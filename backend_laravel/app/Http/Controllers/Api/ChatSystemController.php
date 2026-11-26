<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\Chat\KvMessageStore;
use App\Services\Chat\PushNotificationService;
use App\Services\Chat\RedisSessionRegistry;
use App\Services\Chat\ServiceDiscoveryService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Stateless HTTP Services behind Load Balancer (ByteByteGo Architecture):
 * - Service Discovery (`GET /api/v1/chat/service-discovery`)
 * - 1-on-1 & Small Group (<= 100 members) Channel Metadata
 * - Multi-Device Sync Cursor (`cur_max_message_id`)
 * - Idempotent HTTP Message Send fallback
 * - Push Token Registration (FCM / APNs / WebPush)
 * - Presence Status Lookup
 */
class ChatSystemController extends Controller
{
    private const MAX_GROUP_MEMBERS = 100;

    public function __construct(
        private readonly ServiceDiscoveryService $discovery,
        private readonly KvMessageStore $kvStore,
        private readonly PushNotificationService $pushService,
        private readonly RedisSessionRegistry $sessionRegistry
    ) {
    }

    /**
     * Stateless Service Discovery: returns optimal WebSocket Chat & Presence server URLs.
     */
    public function serviceDiscovery(Request $request): JsonResponse
    {
        $user = $request->user('sanctum');
        $userId = (int) ($user?->id ?? $request->integer('user_id', 0));
        $region = $request->query('region');

        $assignment = $this->discovery->resolveForUser(
            $userId,
            is_string($region) && $region !== '' ? $region : null
        );

        return response()->json([
            'status' => 'ok',
            'data' => $assignment,
        ]);
    }

    /**
     * List 1-on-1 and group channels for the authenticated user.
     */
    public function listChannels(Request $request): JsonResponse
    {
        $userId = (int) $request->user('sanctum')->id;

        $channels = DB::table('chat_channels as c')
            ->join('chat_channel_members as m', 'm.channel_id', '=', 'c.id')
            ->where('m.user_id', $userId)
            ->orderByDesc('c.last_message_at')
            ->orderByDesc('c.id')
            ->select([
                'c.*',
                'm.role as my_role',
                'm.last_read_message_id',
                'm.muted_until',
            ])
            ->limit(100)
            ->get();

        return response()->json([
            'status' => 'ok',
            'data' => $channels,
        ]);
    }

    /**
     * Create or resolve a 1-on-1 direct channel or a small group channel (max 100 members).
     */
    public function createChannel(Request $request): JsonResponse
    {
        $userId = (int) $request->user('sanctum')->id;
        $maxMembers = (int) config('chat.max_group_members', self::MAX_GROUP_MEMBERS);

        $validated = $request->validate([
            'type' => ['required', 'in:direct,group'],
            'name' => ['nullable', 'string', 'max:120'],
            'member_ids' => ['required', 'array', 'min:1', 'max:' . $maxMembers],
            'member_ids.*' => ['integer', 'min:1'],
            'ad_id' => ['nullable', 'integer', 'min:1'],
            'ad_title' => ['nullable', 'string', 'max:255'],
            'ad_price' => ['nullable', 'string', 'max:64'],
            'ad_image' => ['nullable', 'string', 'max:512'],
        ]);

        $memberIds = array_values(array_unique(array_merge(
            [$userId],
            array_map('intval', $validated['member_ids'])
        )));

        if ($validated['type'] === 'direct') {
            if (count($memberIds) !== 2) {
                return response()->json([
                    'message' => 'Direct 1-on-1 chat requires exactly 2 distinct users.',
                ], 422);
            }
            sort($memberIds);
            $adPart = (int) ($validated['ad_id'] ?? 0);
            $channelKey = "dm:{$memberIds[0]}:{$memberIds[1]}:{$adPart}";

            $existing = DB::table('chat_channels')
                ->where('channel_key', $channelKey)
                ->first();

            if ($existing !== null) {
                return response()->json([
                    'status' => 'ok',
                    'data' => $existing,
                ]);
            }
        } else {
            if (count($memberIds) > $maxMembers) {
                return response()->json([
                    'message' => "Small group chats support at most {$maxMembers} members.",
                ], 422);
            }
            $channelKey = 'grp:' . Str::uuid()->toString();
        }

        $channelId = DB::transaction(function () use ($validated, $channelKey, $userId, $memberIds, $maxMembers): int {
            $id = DB::table('chat_channels')->insertGetId([
                'channel_key' => $channelKey,
                'type' => $validated['type'],
                'name' => $validated['name'] ?? null,
                'max_members' => $validated['type'] === 'direct' ? 2 : $maxMembers,
                'ad_id' => $validated['ad_id'] ?? null,
                'ad_title' => $validated['ad_title'] ?? null,
                'ad_price' => $validated['ad_price'] ?? null,
                'ad_image' => $validated['ad_image'] ?? null,
                'created_by' => $userId,
                'last_message_id' => 0,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $memberRows = [];
            foreach ($memberIds as $uid) {
                $memberRows[] = [
                    'channel_id' => $id,
                    'user_id' => $uid,
                    'role' => $uid === $userId ? 'owner' : 'member',
                    'last_read_message_id' => 0,
                    'joined_at' => now(),
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }
            DB::table('chat_channel_members')->insert($memberRows);

            return (int) $id;
        });

        $channel = DB::table('chat_channels')->where('id', $channelId)->first();

        return response()->json([
            'status' => 'ok',
            'data' => $channel,
        ], 201);
    }

    /**
     * Add members to a small group channel while strictly enforcing the 100-member cap.
     */
    public function addMembers(Request $request, int $channelId): JsonResponse
    {
        $userId = (int) $request->user('sanctum')->id;
        $maxMembers = (int) config('chat.max_group_members', self::MAX_GROUP_MEMBERS);

        $channel = DB::table('chat_channels')->where('id', $channelId)->first();
        if ($channel === null || $channel->type !== 'group') {
            return response()->json(['message' => 'Group channel not found.'], 404);
        }

        $isMember = DB::table('chat_channel_members')
            ->where('channel_id', $channelId)
            ->where('user_id', $userId)
            ->exists();
        if (! $isMember) {
            return response()->json(['message' => 'Forbidden.'], 403);
        }

        $validated = $request->validate([
            'member_ids' => ['required', 'array', 'min:1', 'max:' . $maxMembers],
            'member_ids.*' => ['integer', 'min:1'],
        ]);

        $existingIds = DB::table('chat_channel_members')
            ->where('channel_id', $channelId)
            ->pluck('user_id')
            ->map(fn ($id): int => (int) $id)
            ->all();

        $toAdd = array_values(array_diff(
            array_unique(array_map('intval', $validated['member_ids'])),
            $existingIds
        ));

        if (count($existingIds) + count($toAdd) > $maxMembers) {
            return response()->json([
                'message' => "Group member limit ({$maxMembers}) exceeded.",
            ], 422);
        }

        if (! empty($toAdd)) {
            $rows = array_map(fn (int $uid): array => [
                'channel_id' => $channelId,
                'user_id' => $uid,
                'role' => 'member',
                'last_read_message_id' => 0,
                'joined_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ], $toAdd);
            DB::table('chat_channel_members')->insert($rows);
        }

        return response()->json([
            'status' => 'ok',
            'member_count' => count($existingIds) + count($toAdd),
            'max_members' => $maxMembers,
        ]);
    }

    /**
     * Multi-device sync endpoint using per-device `cur_max_message_id`.
     */
    public function syncMessages(Request $request, int $channelId): JsonResponse
    {
        $userId = (int) $request->user('sanctum')->id;
        $deviceId = trim((string) $request->query('device_id', 'default'));
        $limit = max(1, min((int) $request->query('limit', 100), 200));

        $isMember = DB::table('chat_channel_members')
            ->where('channel_id', $channelId)
            ->where('user_id', $userId)
            ->exists();
        if (! $isMember) {
            return response()->json(['message' => 'Forbidden.'], 403);
        }

        $cursorRow = DB::table('chat_device_sync_cursors')
            ->where('user_id', $userId)
            ->where('device_id', $deviceId)
            ->where('channel_id', $channelId)
            ->first();

        $afterId = $request->has('after_message_id')
            ? max(0, (int) $request->query('after_message_id', 0))
            : (int) ($cursorRow?->cur_max_message_id ?? 0);

        $messages = $afterId > 0
            ? $this->kvStore->syncAfter($channelId, $afterId, $limit)
            : $this->kvStore->getRecent($channelId, $limit);

        $newMaxId = $afterId;
        foreach ($messages as $msg) {
            if (($msg['message_id'] ?? 0) > $newMaxId) {
                $newMaxId = (int) $msg['message_id'];
            }
        }

        if ($newMaxId > 0) {
            DB::table('chat_device_sync_cursors')->updateOrInsert(
                [
                    'user_id' => $userId,
                    'device_id' => $deviceId,
                    'channel_id' => $channelId,
                ],
                [
                    'cur_max_message_id' => $newMaxId,
                    'last_synced_at' => now(),
                    'updated_at' => now(),
                ]
            );
        }

        return response()->json([
            'status' => 'ok',
            'channel_id' => $channelId,
            'device_id' => $deviceId,
            'cur_max_message_id' => $newMaxId,
            'messages' => $messages,
        ]);
    }

    /**
     * HTTP fallback send with `client_message_id` idempotency, KV persistence,
     * and offline third-party push notification dispatch.
     */
    public function sendMessage(Request $request, int $channelId): JsonResponse
    {
        $user = $request->user('sanctum');
        $userId = (int) $user->id;

        $channel = DB::table('chat_channels')->where('id', $channelId)->first();
        if ($channel === null) {
            return response()->json(['message' => 'Channel not found.'], 404);
        }

        $memberIds = DB::table('chat_channel_members')
            ->where('channel_id', $channelId)
            ->pluck('user_id')
            ->map(fn ($id): int => (int) $id)
            ->all();

        if (! in_array($userId, $memberIds, true)) {
            return response()->json(['message' => 'Forbidden.'], 403);
        }

        $validated = $request->validate([
            'client_message_id' => ['required', 'string', 'max:128'],
            'device_id' => ['nullable', 'string', 'max:128'],
            'type' => ['required', 'in:text,audio,image'],
            'body' => ['nullable', 'string', 'max:8000'],
            'metadata' => ['nullable', 'array'],
        ]);

        $stored = $this->kvStore->putMessage(
            $channelId,
            $userId,
            $validated['client_message_id'],
            $validated['type'],
            $validated['body'] ?? '',
            $validated['metadata'] ?? []
        );

        $message = $stored['message'];

        if (! $stored['deduplicated']) {
            $preview = $validated['type'] === 'audio'
                ? 'رسالة صوتية'
                : ($validated['type'] === 'image' ? 'صورة' : Str::limit((string) ($validated['body'] ?? ''), 120));

            DB::table('chat_channels')
                ->where('id', $channelId)
                ->update([
                    'last_message_id' => $message['message_id'],
                    'last_message_preview' => $preview,
                    'last_message_at' => now(),
                    'updated_at' => now(),
                ]);

            $recipientIds = array_values(array_filter(
                $memberIds,
                fn (int $id): bool => $id !== $userId
            ));

            // Store-and-Forward: queue message for offline/unacknowledged recipients
            $this->kvStore->enqueuePendingDeliveries(
                $channelId,
                (int) $message['message_id'],
                $userId,
                $recipientIds
            );

            // Route directly to each online recipient's active WebSocket gateway node via Redis Session Registry
            $offlineRecipientIds = [];
            foreach ($recipientIds as $recipientId) {
                $routeResult = $this->sessionRegistry->routeFrameToUser($recipientId, [
                    'event' => 'message',
                    'data' => $message,
                ]);
                if (! $routeResult['has_foreground_device']) {
                    $offlineRecipientIds[] = $recipientId;
                }
            }

            if (! empty($offlineRecipientIds)) {
                $this->pushService->notifyOfflineRecipients(
                    $offlineRecipientIds,
                    (string) ($user->name ?? 'Apolo User'),
                    $message,
                    is_string($channel->ad_title) ? $channel->ad_title : null
                );
            }
        }

        return response()->json([
            'status' => 'ok',
            'ack_status' => $message['ack_status'] ?? 'sent',
            'deduplicated' => $stored['deduplicated'],
            'data' => $message,
        ], $stored['deduplicated'] ? 200 : 201);
    }

    /**
     * Explicit Delivered (`✓✓`) or Read (`✓✓`) ACK endpoint (`POST /api/v1/chat/channels/{channelId}/ack`).
     * Purges recipient's Store-and-Forward pending queue and propagates the ACK in real time
     * back to the sender's active WebSocket gateway node via Redis Session Registry.
     */
    public function acknowledgeMessages(Request $request, int $channelId): JsonResponse
    {
        $userId = (int) $request->user('sanctum')->id;

        $isMember = DB::table('chat_channel_members')
            ->where('channel_id', $channelId)
            ->where('user_id', $userId)
            ->exists();
        if (! $isMember) {
            return response()->json(['message' => 'Forbidden.'], 403);
        }

        $validated = $request->validate([
            'ack_type' => ['required', 'in:delivered,read'],
            'message_ids' => ['nullable', 'array', 'max:200'],
            'message_ids.*' => ['integer', 'min:1'],
            'up_to_message_id' => ['nullable', 'integer', 'min:1'],
        ]);

        $ackType = (string) $validated['ack_type'];
        $messageIds = array_map('intval', (array) ($validated['message_ids'] ?? []));
        $upToId = isset($validated['up_to_message_id']) ? (int) $validated['up_to_message_id'] : null;

        $updated = $this->kvStore->acknowledgeMessages(
            $channelId,
            $userId,
            $ackType,
            $messageIds,
            $upToId
        );

        if ($ackType === 'read' && $upToId !== null && $upToId > 0) {
            DB::table('chat_channel_members')
                ->where('channel_id', $channelId)
                ->where('user_id', $userId)
                ->where('last_read_message_id', '<', $upToId)
                ->update([
                    'last_read_message_id' => $upToId,
                    'updated_at' => now(),
                ]);
        }

        // Group updated messages by original sender and push real-time ACK via Redis Session Registry
        $bySender = [];
        foreach ($updated as $msg) {
            $senderId = (int) ($msg['sender_id'] ?? 0);
            if ($senderId > 0 && $senderId !== $userId) {
                $bySender[$senderId][] = $msg;
            }
        }

        $nowIso = now()->toIso8601String();
        foreach ($bySender as $senderId => $msgs) {
            $lastId = (string) ($msgs[count($msgs) - 1]['message_id'] ?? '0');
            $frame = $ackType === 'read'
                ? [
                    'event' => 'read_receipt',
                    'channel_id' => (string) $channelId,
                    'user_id' => $userId,
                    'ack_status' => 'read',
                    'last_read_message_id' => $lastId,
                    'client_message_ids' => array_values(array_map(fn (array $m): string => (string) $m['client_message_id'], $msgs)),
                    'read_at' => $nowIso,
                ]
                : [
                    'event' => 'delivery_receipt',
                    'channel_id' => (string) $channelId,
                    'recipient_id' => $userId,
                    'ack_status' => 'delivered',
                    'message_ids' => array_values(array_map(fn (array $m): string => (string) $m['message_id'], $msgs)),
                    'client_message_ids' => array_values(array_map(fn (array $m): string => (string) $m['client_message_id'], $msgs)),
                    'last_delivered_message_id' => $lastId,
                    'delivered_at' => $nowIso,
                ];

            $this->sessionRegistry->routeFrameToUser($senderId, $frame);
        }

        return response()->json([
            'status' => 'ok',
            'ack_type' => $ackType,
            'updated_count' => count($updated),
        ]);
    }

    /**
     * Register device push token for APNs / FCM / WebPush.
     */
    public function registerPushToken(Request $request): JsonResponse
    {
        $userId = (int) $request->user('sanctum')->id;

        $validated = $request->validate([
            'device_id' => ['required', 'string', 'max:128'],
            'platform' => ['required', 'in:ios,android,web'],
            'provider' => ['required', 'in:apns,fcm,webpush'],
            'token' => ['required', 'string', 'max:512'],
        ]);

        DB::table('chat_push_tokens')->updateOrInsert(
            [
                'user_id' => $userId,
                'device_id' => $validated['device_id'],
            ],
            [
                'platform' => $validated['platform'],
                'provider' => $validated['provider'],
                'token' => $validated['token'],
                'is_active' => true,
                'last_seen_at' => now(),
                'updated_at' => now(),
            ]
        );

        return response()->json(['status' => 'ok']);
    }

    /**
     * Deactivate a device push token (e.g. on user logout).
     */
    public function unregisterPushToken(Request $request): JsonResponse
    {
        $userId = (int) $request->user('sanctum')->id;

        $validated = $request->validate([
            'device_id' => ['required', 'string', 'max:128'],
        ]);

        DB::table('chat_push_tokens')
            ->where('user_id', $userId)
            ->where('device_id', $validated['device_id'])
            ->update([
                'is_active' => false,
                'updated_at' => now(),
            ]);

        return response()->json(['status' => 'ok']);
    }

    /**
     * Dispatch a push notification to a recipient's registered mobile devices
     * (used for Firestore real-time chat messages, incoming calls, and alerts).
     */
    public function dispatchDirectPush(Request $request): JsonResponse
    {
        $senderId = (int) $request->user('sanctum')->id;

        $validated = $request->validate([
            'recipient_user_id' => ['required', 'integer', 'min:1'],
            'title' => ['required', 'string', 'max:120'],
            'body' => ['required', 'string', 'max:300'],
            'type' => ['nullable', 'string', 'max:40'],
            'channel_id' => ['nullable', 'string', 'in:apolo_messages,apolo_calls,apolo_alerts'],
            'data' => ['nullable', 'array'],
        ]);

        $recipientId = (int) $validated['recipient_user_id'];
        if ($recipientId === $senderId) {
            return response()->json(['status' => 'ok', 'dispatched' => 0]);
        }

        $type = (string) ($validated['type'] ?? 'message');
        $channelId = (string) ($validated['channel_id'] ?? match (true) {
            str_contains($type, 'call') => 'apolo_calls',
            str_contains($type, 'message') || str_contains($type, 'chat') => 'apolo_messages',
            default => 'apolo_alerts',
        });

        $payloadData = is_array($validated['data'] ?? null) ? $validated['data'] : [];
        $payloadData['type'] = $type;
        $payloadData['sender_id'] = (string) $senderId;

        $dispatched = $this->pushService->sendToUser(
            userId: $recipientId,
            title: (string) $validated['title'],
            body: (string) $validated['body'],
            data: $payloadData,
            channelId: $channelId
        );

        return response()->json([
            'status' => 'ok',
            'dispatched' => $dispatched,
        ]);
    }

    /**
     * Batch presence lookup for a list of user IDs.
     */
    public function getPresence(Request $request): JsonResponse
    {
        $rawIds = (string) $request->query('user_ids', '');
        $userIds = array_values(array_unique(array_filter(
            array_map('intval', explode(',', $rawIds)),
            fn (int $id): bool => $id > 0
        )));

        if (empty($userIds)) {
            return response()->json(['status' => 'ok', 'data' => []]);
        }

        $timeoutSeconds = (int) config('chat.presence_timeout_seconds', 30);
        $cutoff = now()->subSeconds($timeoutSeconds);

        $rows = DB::table('chat_user_presence')
            ->whereIn('user_id', array_slice($userIds, 0, 100))
            ->get()
            ->keyBy('user_id');

        $result = [];
        foreach (array_slice($userIds, 0, 100) as $uid) {
            $row = $rows->get($uid);
            $isOnline = $row !== null
                && $row->status === 'online'
                && $row->last_heartbeat_at !== null
                && $row->last_heartbeat_at >= $cutoff;

            $result[(string) $uid] = [
                'user_id' => $uid,
                'status' => $isOnline ? 'online' : 'offline',
                'last_active_at' => $row?->last_active_at,
            ];
        }

        return response()->json([
            'status' => 'ok',
            'data' => $result,
        ]);
    }
}
