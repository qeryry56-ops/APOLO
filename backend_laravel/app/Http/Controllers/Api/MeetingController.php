<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\Meetings\LiveKitRoomAdminService;
use App\Services\Meetings\LiveKitTokenService;
use App\Services\Meetings\LiveKitWebhookVerifier;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use RuntimeException;

/**
 * SFU Group Meeting Control Plane (8–25+ Participants via LiveKit SFU).
 * Handles room creation, Sanctum-authenticated short-lived JWT minting,
 * STUN/TURN/TURNS ice config delivery, E2EE room metadata, host moderation,
 * and signed LiveKit webhook synchronization.
 */
class MeetingController extends Controller
{
    public function __construct(
        private readonly LiveKitTokenService $tokenService,
        private readonly LiveKitRoomAdminService $roomAdmin,
        private readonly LiveKitWebhookVerifier $webhookVerifier
    ) {
    }

    /**
     * Create a new SFU group meeting room (`POST /api/v1/meetings`).
     */
    public function createMeeting(Request $request): JsonResponse
    {
        $user = $request->user('sanctum');
        $userId = (int) $user->id;
        $hardMax = (int) config('meetings.hard_max_participants', 50);
        $defaultMax = (int) config('meetings.default_max_participants', 25);

        $validated = $request->validate([
            'title' => ['nullable', 'string', 'max:160'],
            'channel_id' => ['nullable', 'integer', 'min:1'],
            'ad_id' => ['nullable', 'integer', 'min:1'],
            'max_participants' => ['nullable', 'integer', 'min:2', 'max:' . $hardMax],
            'e2ee_enabled' => ['nullable', 'boolean'],
            'e2ee_key_hint' => ['nullable', 'string', 'max:64', 'regex:/^[A-Za-z0-9_\-:]+$/'],
            'mute_on_entry' => ['nullable', 'boolean'],
            'region' => ['nullable', 'string', 'in:ma-casablanca,eu-west'],
        ]);

        if (! empty($validated['channel_id']) && Schema::hasTable('chat_channel_members')) {
            $isMember = DB::table('chat_channel_members')
                ->where('channel_id', (int) $validated['channel_id'])
                ->where('user_id', $userId)
                ->exists();

            if (! $isMember) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'You are not a member of the specified chat channel.',
                ], 403);
            }
        }

        $roomCode = $this->generateUniqueRoomCode();
        $livekitRoomName = 'apolo_mtg_' . str_replace('-', '_', $roomCode) . '_' . Str::lower(Str::random(6));
        $maxParticipants = (int) ($validated['max_participants'] ?? $defaultMax);
        $region = (string) ($validated['region'] ?? 'ma-casablanca');
        $title = trim((string) ($validated['title'] ?? ''));
        if ($title === '') {
            $title = 'اجتماع Apolo المباشر';
        }

        $displayName = $this->resolveDisplayName($user);
        $avatarUrl = $this->resolveAvatarUrl($user);
        $identity = "user_{$userId}";

        $roomId = DB::transaction(function () use (
            $roomCode,
            $livekitRoomName,
            $title,
            $userId,
            $validated,
            $maxParticipants,
            $region,
            $identity,
            $displayName,
            $avatarUrl
        ): int {
            $id = DB::table('meeting_rooms')->insertGetId([
                'room_code' => $roomCode,
                'livekit_room_name' => $livekitRoomName,
                'title' => $title,
                'host_user_id' => $userId,
                'channel_id' => $validated['channel_id'] ?? null,
                'ad_id' => $validated['ad_id'] ?? null,
                'max_participants' => $maxParticipants,
                'e2ee_enabled' => (bool) ($validated['e2ee_enabled'] ?? false),
                'e2ee_key_hint' => ($validated['e2ee_enabled'] ?? false) ? ($validated['e2ee_key_hint'] ?? null) : null,
                'is_locked' => false,
                'mute_on_entry' => (bool) ($validated['mute_on_entry'] ?? false),
                'region' => $region,
                'status' => 'active',
                'active_participants_count' => 0,
                'started_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::table('meeting_participants')->insert([
                'meeting_room_id' => $id,
                'user_id' => $userId,
                'participant_identity' => $identity,
                'display_name' => $displayName,
                'avatar_url' => $avatarUrl,
                'role' => 'host',
                'state' => 'invited',
                'can_publish' => true,
                'can_publish_sources_screen' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            return (int) $id;
        });

        $this->roomAdmin->ensureRoomCreated(
            $livekitRoomName,
            $maxParticipants,
            (int) config('meetings.empty_timeout_seconds', 300)
        );

        $room = DB::table('meeting_rooms')->where('id', $roomId)->first();

        return response()->json([
            'status' => 'success',
            'data' => $this->formatRoomSummary($room, 'host'),
        ], 201);
    }

    /**
     * Inspect meeting room lobby metadata before joining (`GET /api/v1/meetings/{roomCode}`).
     */
    public function showMeeting(Request $request, string $roomCode): JsonResponse
    {
        $user = $request->user('sanctum');
        $room = DB::table('meeting_rooms')->where('room_code', strtolower(trim($roomCode)))->first();

        if ($room === null) {
            return response()->json([
                'status' => 'error',
                'message' => 'Meeting room not found.',
            ], 404);
        }

        $participant = DB::table('meeting_participants')
            ->where('meeting_room_id', $room->id)
            ->where('user_id', (int) $user->id)
            ->first();

        $myRole = $participant?->role ?? (((int) $room->host_user_id === (int) $user->id) ? 'host' : 'participant');

        return response()->json([
            'status' => 'success',
            'data' => $this->formatRoomSummary($room, $myRole),
        ]);
    }

    /**
     * Authorize participant and issue short-lived SFU token + ICE/TURN + SVC config
     * (`POST /api/v1/meetings/{roomCode}/join`).
     */
    public function joinMeeting(Request $request, string $roomCode): JsonResponse
    {
        if (! $this->tokenService->isConfigured()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Meeting SFU service is not configured on this server.',
            ], 503);
        }

        $user = $request->user('sanctum');
        $userId = (int) $user->id;
        $normalizedCode = strtolower(trim($roomCode));

        $validated = $request->validate([
            'display_name' => ['nullable', 'string', 'max:120'],
            'region' => ['nullable', 'string', 'in:ma-casablanca,eu-west'],
        ]);

        $room = DB::table('meeting_rooms')->where('room_code', $normalizedCode)->first();
        if ($room === null) {
            return response()->json([
                'status' => 'error',
                'message' => 'Meeting room not found.',
            ], 404);
        }

        if ($room->status === 'ended') {
            return response()->json([
                'status' => 'error',
                'message' => 'This meeting has already ended.',
            ], 410);
        }

        if ($room->channel_id !== null && Schema::hasTable('chat_channel_members')) {
            $isChannelMember = DB::table('chat_channel_members')
                ->where('channel_id', (int) $room->channel_id)
                ->where('user_id', $userId)
                ->exists();

            if (! $isChannelMember && (int) $room->host_user_id !== $userId) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Only members of this channel may join the meeting.',
                ], 403);
            }
        }

        $existing = DB::table('meeting_participants')
            ->where('meeting_room_id', $room->id)
            ->where('user_id', $userId)
            ->first();

        if ($existing !== null && $existing->state === 'kicked') {
            return response()->json([
                'status' => 'error',
                'message' => 'You were removed from this meeting by the host.',
            ], 403);
        }

        $isHostOrCohost = ((int) $room->host_user_id === $userId)
            || ($existing !== null && in_array($existing->role, ['host', 'cohost'], true));

        if ((bool) $room->is_locked && ! $isHostOrCohost && ($existing === null || $existing->state !== 'joined')) {
            return response()->json([
                'status' => 'error',
                'message' => 'This meeting room is currently locked by the host.',
            ], 423);
        }

        $activeJoinedCount = DB::table('meeting_participants')
            ->where('meeting_room_id', $room->id)
            ->where('state', 'joined')
            ->where('user_id', '!=', $userId)
            ->count();

        if ($activeJoinedCount >= (int) $room->max_participants && ! $isHostOrCohost) {
            return response()->json([
                'status' => 'error',
                'message' => "Meeting capacity ({$room->max_participants} participants) reached.",
            ], 429);
        }

        $displayName = trim((string) ($validated['display_name'] ?? '')) ?: $this->resolveDisplayName($user);
        $avatarUrl = $this->resolveAvatarUrl($user);
        $identity = "user_{$userId}";
        $role = ((int) $room->host_user_id === $userId) ? 'host' : ($existing?->role ?? 'participant');
        $canPublish = $existing !== null ? (bool) $existing->can_publish : true;
        $allowScreenShare = $existing !== null ? (bool) $existing->can_publish_sources_screen : true;

        DB::transaction(function () use (
            $room,
            $userId,
            $identity,
            $displayName,
            $avatarUrl,
            $role,
            $canPublish,
            $allowScreenShare
        ): void {
            DB::table('meeting_participants')->updateOrInsert(
                [
                    'meeting_room_id' => $room->id,
                    'user_id' => $userId,
                ],
                [
                    'participant_identity' => $identity,
                    'display_name' => $displayName,
                    'avatar_url' => $avatarUrl,
                    'role' => $role,
                    'state' => 'joined',
                    'can_publish' => $canPublish,
                    'can_publish_sources_screen' => $allowScreenShare,
                    'joined_at' => now(),
                    'left_at' => null,
                    'updated_at' => now(),
                ]
            );

            $joinedCount = DB::table('meeting_participants')
                ->where('meeting_room_id', $room->id)
                ->where('state', 'joined')
                ->count();

            DB::table('meeting_rooms')
                ->where('id', $room->id)
                ->update([
                    'active_participants_count' => $joinedCount,
                    'updated_at' => now(),
                ]);
        });

        $tokenBundle = $this->tokenService->createParticipantToken(
            $room->livekit_room_name,
            $identity,
            $displayName,
            [
                'can_publish' => $canPublish,
                'can_subscribe' => true,
                'can_publish_data' => true,
                'allow_screen_share' => $allowScreenShare,
                'room_admin' => in_array($role, ['host', 'cohost'], true),
                'metadata' => [
                    'user_id' => $userId,
                    'role' => $role,
                    'avatar_url' => $avatarUrl,
                    'verified' => (bool) ($user->is_verified ?? false),
                ],
            ]
        );

        $preferredRegion = (string) ($validated['region'] ?? $room->region ?? 'ma-casablanca');
        $updatedRoom = DB::table('meeting_rooms')->where('id', $room->id)->first();

        return response()->json([
            'status' => 'success',
            'data' => [
                'room' => $this->formatRoomSummary($updatedRoom, $role),
                'sfu' => [
                    'provider' => 'livekit',
                    'topology' => 'sfu',
                    'ws_url' => $this->tokenService->resolveWsUrl($preferredRegion),
                    'access_token' => $tokenBundle['token'],
                    'expires_at' => $tokenBundle['expires_at'],
                    'ttl_seconds' => $tokenBundle['ttl_seconds'],
                    'participant_identity' => $identity,
                    'ice_transport_policy' => config('meetings.ice_transport_policy', 'all'),
                    'ice_servers' => $this->tokenService->buildIceServers($identity),
                    'media_policy' => config('meetings.media_defaults'),
                ],
            ],
        ]);
    }

    /**
     * Refresh short-lived SFU token for long-running calls (`POST /api/v1/meetings/{roomCode}/token/refresh`).
     */
    public function refreshToken(Request $request, string $roomCode): JsonResponse
    {
        return $this->joinMeeting($request, $roomCode);
    }

    /**
     * Participant clean leave notification (`POST /api/v1/meetings/{roomCode}/leave`).
     */
    public function leaveMeeting(Request $request, string $roomCode): JsonResponse
    {
        $userId = (int) $request->user('sanctum')->id;
        $room = DB::table('meeting_rooms')->where('room_code', strtolower(trim($roomCode)))->first();

        if ($room === null) {
            return response()->json(['status' => 'error', 'message' => 'Meeting not found.'], 404);
        }

        DB::transaction(function () use ($room, $userId): void {
            DB::table('meeting_participants')
                ->where('meeting_room_id', $room->id)
                ->where('user_id', $userId)
                ->where('state', 'joined')
                ->update([
                    'state' => 'left',
                    'left_at' => now(),
                    'updated_at' => now(),
                ]);

            $joinedCount = DB::table('meeting_participants')
                ->where('meeting_room_id', $room->id)
                ->where('state', 'joined')
                ->count();

            DB::table('meeting_rooms')
                ->where('id', $room->id)
                ->update([
                    'active_participants_count' => $joinedCount,
                    'updated_at' => now(),
                ]);
        });

        return response()->json(['status' => 'success']);
    }

    /**
     * Host / Cohost moderation actions (`POST /api/v1/meetings/{roomCode}/moderate`).
     */
    public function moderateParticipant(Request $request, string $roomCode): JsonResponse
    {
        $actorId = (int) $request->user('sanctum')->id;
        $room = DB::table('meeting_rooms')->where('room_code', strtolower(trim($roomCode)))->first();

        if ($room === null || $room->status === 'ended') {
            return response()->json(['status' => 'error', 'message' => 'Active meeting not found.'], 404);
        }

        $actorRecord = DB::table('meeting_participants')
            ->where('meeting_room_id', $room->id)
            ->where('user_id', $actorId)
            ->first();

        $isHost = (int) $room->host_user_id === $actorId;
        $isCohost = $actorRecord !== null && $actorRecord->role === 'cohost';

        if (! $isHost && ! $isCohost) {
            return response()->json(['status' => 'error', 'message' => 'Host or cohost permissions required.'], 403);
        }

        $validated = $request->validate([
            'action' => ['required', 'string', 'in:kick,mute_track,lock_room,unlock_room,grant_cohost,revoke_cohost,disable_publish,enable_publish'],
            'target_user_id' => ['nullable', 'integer', 'min:1'],
            'track_sid' => ['nullable', 'string', 'max:96'],
        ]);

        $action = $validated['action'];

        if (in_array($action, ['lock_room', 'unlock_room'], true)) {
            $locked = $action === 'lock_room';
            DB::table('meeting_rooms')->where('id', $room->id)->update([
                'is_locked' => $locked,
                'updated_at' => now(),
            ]);

            return response()->json([
                'status' => 'success',
                'is_locked' => $locked,
            ]);
        }

        $targetUserId = (int) ($validated['target_user_id'] ?? 0);
        if ($targetUserId <= 0) {
            return response()->json(['status' => 'error', 'message' => 'target_user_id is required.'], 422);
        }

        if ($targetUserId === (int) $room->host_user_id) {
            return response()->json(['status' => 'error', 'message' => 'Cannot moderate the primary meeting host.'], 403);
        }

        $target = DB::table('meeting_participants')
            ->where('meeting_room_id', $room->id)
            ->where('user_id', $targetUserId)
            ->first();

        if ($target === null) {
            return response()->json(['status' => 'error', 'message' => 'Participant not found in room.'], 404);
        }

        if ($action === 'kick') {
            DB::table('meeting_participants')
                ->where('id', $target->id)
                ->update([
                    'state' => 'kicked',
                    'left_at' => now(),
                    'updated_at' => now(),
                ]);

            $joinedCount = DB::table('meeting_participants')
                ->where('meeting_room_id', $room->id)
                ->where('state', 'joined')
                ->count();

            DB::table('meeting_rooms')->where('id', $room->id)->update([
                'active_participants_count' => $joinedCount,
                'updated_at' => now(),
            ]);

            $this->roomAdmin->removeParticipant($room->livekit_room_name, $target->participant_identity);

            return response()->json([
                'status' => 'success',
                'action' => 'kick',
                'e2ee_ratchet_required' => (bool) $room->e2ee_enabled,
            ]);
        }

        if ($action === 'mute_track') {
            $trackSid = trim((string) ($validated['track_sid'] ?? ''));
            if ($trackSid === '') {
                return response()->json(['status' => 'error', 'message' => 'track_sid is required for mute_track.'], 422);
            }
            $this->roomAdmin->mutePublishedTrack($room->livekit_room_name, $target->participant_identity, $trackSid, true);

            return response()->json(['status' => 'success', 'action' => 'mute_track']);
        }

        if (in_array($action, ['grant_cohost', 'revoke_cohost'], true)) {
            if (! $isHost) {
                return response()->json(['status' => 'error', 'message' => 'Only the primary host can manage cohosts.'], 403);
            }
            $newRole = $action === 'grant_cohost' ? 'cohost' : 'participant';
            DB::table('meeting_participants')->where('id', $target->id)->update([
                'role' => $newRole,
                'updated_at' => now(),
            ]);

            return response()->json(['status' => 'success', 'role' => $newRole]);
        }

        if (in_array($action, ['disable_publish', 'enable_publish'], true)) {
            $canPublish = $action === 'enable_publish';
            DB::table('meeting_participants')->where('id', $target->id)->update([
                'can_publish' => $canPublish,
                'updated_at' => now(),
            ]);
            $this->roomAdmin->updateParticipantPermissions($room->livekit_room_name, $target->participant_identity, $canPublish);

            return response()->json(['status' => 'success', 'can_publish' => $canPublish]);
        }

        return response()->json(['status' => 'ok']);
    }

    /**
     * End meeting room for all participants (`POST /api/v1/meetings/{roomCode}/end`).
     */
    public function endMeeting(Request $request, string $roomCode): JsonResponse
    {
        $userId = (int) $request->user('sanctum')->id;
        $room = DB::table('meeting_rooms')->where('room_code', strtolower(trim($roomCode)))->first();

        if ($room === null) {
            return response()->json(['status' => 'error', 'message' => 'Meeting not found.'], 404);
        }

        if ((int) $room->host_user_id !== $userId) {
            return response()->json(['status' => 'error', 'message' => 'Only the host can end the meeting for everyone.'], 403);
        }

        DB::transaction(function () use ($room): void {
            DB::table('meeting_rooms')->where('id', $room->id)->update([
                'status' => 'ended',
                'active_participants_count' => 0,
                'ended_at' => now(),
                'updated_at' => now(),
            ]);

            DB::table('meeting_participants')
                ->where('meeting_room_id', $room->id)
                ->where('state', 'joined')
                ->update([
                    'state' => 'left',
                    'left_at' => now(),
                    'updated_at' => now(),
                ]);
        });

        $this->roomAdmin->deleteRoom($room->livekit_room_name);

        return response()->json(['status' => 'success']);
    }

    /**
     * Signed LiveKit SFU Webhook receiver (`POST /api/v1/meetings/webhook`).
     */
    public function handleWebhook(Request $request): JsonResponse
    {
        try {
            $eventPayload = $this->webhookVerifier->verifyAndDecode(
                (string) $request->getContent(),
                $request->header('Authorization')
            );
        } catch (RuntimeException $e) {
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage(),
            ], 401);
        }

        $eventType = (string) ($eventPayload['event'] ?? '');
        $roomData = is_array($eventPayload['room'] ?? null) ? $eventPayload['room'] : [];
        $livekitRoomName = (string) ($roomData['name'] ?? '');

        if ($livekitRoomName === '') {
            return response()->json(['status' => 'ignored']);
        }

        $room = DB::table('meeting_rooms')->where('livekit_room_name', $livekitRoomName)->first();
        if ($room === null) {
            return response()->json(['status' => 'ignored']);
        }

        $participantData = is_array($eventPayload['participant'] ?? null) ? $eventPayload['participant'] : [];
        $identity = (string) ($participantData['identity'] ?? '');

        if ($eventType === 'participant_joined' && $identity !== '') {
            DB::table('meeting_participants')
                ->where('meeting_room_id', $room->id)
                ->where('participant_identity', $identity)
                ->where('state', '!=', 'kicked')
                ->update([
                    'state' => 'joined',
                    'joined_at' => now(),
                    'left_at' => null,
                    'updated_at' => now(),
                ]);
        } elseif ($eventType === 'participant_left' && $identity !== '') {
            DB::table('meeting_participants')
                ->where('meeting_room_id', $room->id)
                ->where('participant_identity', $identity)
                ->where('state', 'joined')
                ->update([
                    'state' => 'left',
                    'left_at' => now(),
                    'updated_at' => now(),
                ]);
        } elseif ($eventType === 'room_finished') {
            DB::table('meeting_rooms')->where('id', $room->id)->update([
                'status' => 'ended',
                'active_participants_count' => 0,
                'ended_at' => now(),
                'updated_at' => now(),
            ]);

            DB::table('meeting_participants')
                ->where('meeting_room_id', $room->id)
                ->where('state', 'joined')
                ->update([
                    'state' => 'left',
                    'left_at' => now(),
                    'updated_at' => now(),
                ]);

            return response()->json(['status' => 'ok']);
        }

        $joinedCount = DB::table('meeting_participants')
            ->where('meeting_room_id', $room->id)
            ->where('state', 'joined')
            ->count();

        DB::table('meeting_rooms')->where('id', $room->id)->update([
            'active_participants_count' => $joinedCount,
            'updated_at' => now(),
        ]);

        return response()->json(['status' => 'ok']);
    }

    /**
     * @return array<string, mixed>
     */
    private function formatRoomSummary(object $room, string $myRole): array
    {
        return [
            'room_code' => $room->room_code,
            'title' => $room->title,
            'host_user_id' => (int) $room->host_user_id,
            'channel_id' => $room->channel_id !== null ? (int) $room->channel_id : null,
            'ad_id' => $room->ad_id !== null ? (int) $room->ad_id : null,
            'max_participants' => (int) $room->max_participants,
            'active_participants_count' => (int) $room->active_participants_count,
            'e2ee_enabled' => (bool) $room->e2ee_enabled,
            'e2ee_key_hint' => $room->e2ee_key_hint,
            'is_locked' => (bool) $room->is_locked,
            'mute_on_entry' => (bool) $room->mute_on_entry,
            'region' => $room->region,
            'status' => $room->status,
            'my_role' => $myRole,
            'started_at' => $room->started_at,
            'ended_at' => $room->ended_at,
        ];
    }

    private function generateUniqueRoomCode(): string
    {
        $alphabet = 'abcdefghjkmnpqrstuvwxyz23456789';
        $segment = static function (int $len) use ($alphabet): string {
            $out = '';
            $maxIdx = strlen($alphabet) - 1;
            for ($i = 0; $i < $len; $i++) {
                $out .= $alphabet[random_int(0, $maxIdx)];
            }

            return $out;
        };

        for ($attempt = 0; $attempt < 8; $attempt++) {
            $code = 'apo-' . $segment(4) . '-' . $segment(4);
            $exists = DB::table('meeting_rooms')->where('room_code', $code)->exists();
            if (! $exists) {
                return $code;
            }
        }

        return 'apo-' . Str::lower(Str::random(4)) . '-' . Str::lower(Str::random(4));
    }

    private function resolveDisplayName(object $user): string
    {
        $candidates = [
            $user->name ?? null,
            $user->full_name ?? null,
            $user->username ?? null,
        ];

        foreach ($candidates as $candidate) {
            if (is_string($candidate) && trim($candidate) !== '') {
                return trim($candidate);
            }
        }

        return 'مستخدم Apolo #' . ($user->id ?? '');
    }

    private function resolveAvatarUrl(object $user): ?string
    {
        foreach (['avatar_url', 'avatar', 'profile_photo_url'] as $field) {
            $val = $user->{$field} ?? null;
            if (is_string($val) && trim($val) !== '') {
                return trim($val);
            }
        }

        return null;
    }
}
