<?php

namespace App\Services\Meetings;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * Server-side control plane client for LiveKit SFU Twirp RoomService RPCs.
 * Allows hosts to create rooms with participant limits, mute/remove participants,
 * and tear down ended meetings directly on the SFU cluster.
 */
class LiveKitRoomAdminService
{
    public function __construct(
        private readonly LiveKitTokenService $tokenService
    ) {
    }

    public function ensureRoomCreated(string $livekitRoomName, int $maxParticipants, int $emptyTimeoutSeconds = 300): bool
    {
        return $this->callRoomService('CreateRoom', $livekitRoomName, [
            'name' => $livekitRoomName,
            'max_participants' => $maxParticipants,
            'empty_timeout' => $emptyTimeoutSeconds,
        ]);
    }

    public function removeParticipant(string $livekitRoomName, string $identity): bool
    {
        return $this->callRoomService('RemoveParticipant', $livekitRoomName, [
            'room' => $livekitRoomName,
            'identity' => $identity,
        ]);
    }

    public function mutePublishedTrack(string $livekitRoomName, string $identity, string $trackSid, bool $muted = true): bool
    {
        return $this->callRoomService('MutePublishedTrack', $livekitRoomName, [
            'room' => $livekitRoomName,
            'identity' => $identity,
            'track_sid' => $trackSid,
            'muted' => $muted,
        ]);
    }

    public function updateParticipantPermissions(
        string $livekitRoomName,
        string $identity,
        bool $canPublish,
        bool $canSubscribe = true,
        bool $canPublishData = true
    ): bool {
        return $this->callRoomService('UpdateParticipant', $livekitRoomName, [
            'room' => $livekitRoomName,
            'identity' => $identity,
            'permission' => [
                'can_publish' => $canPublish,
                'can_subscribe' => $canSubscribe,
                'can_publish_data' => $canPublishData,
            ],
        ]);
    }

    public function deleteRoom(string $livekitRoomName): bool
    {
        return $this->callRoomService('DeleteRoom', $livekitRoomName, [
            'room' => $livekitRoomName,
        ]);
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    private function callRoomService(string $method, string $livekitRoomName, array $payload): bool
    {
        if (! $this->tokenService->isConfigured()) {
            return false;
        }

        $baseUrl = rtrim((string) config('meetings.http_url', ''), '/');
        if ($baseUrl === '') {
            return false;
        }

        try {
            $adminJwt = $this->tokenService->createServerAdminToken($livekitRoomName);
            $response = Http::timeout(5)
                ->withToken($adminJwt)
                ->acceptJson()
                ->post("{$baseUrl}/twirp/livekit.RoomService/{$method}", $payload);

            if (! $response->successful()) {
                Log::warning("LiveKit RoomService {$method} non-2xx response", [
                    'room' => $livekitRoomName,
                    'status' => $response->status(),
                ]);

                return false;
            }

            return true;
        } catch (Throwable $e) {
            Log::warning("LiveKit RoomService {$method} failed", [
                'room' => $livekitRoomName,
                'error' => $e->getMessage(),
            ]);

            return false;
        }
    }
}
