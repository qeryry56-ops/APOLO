<?php

namespace App\Services\Chat;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Third-Party Push Notification Integration (ByteByteGo Push Notification Service).
 *
 * Dispatches APNs / FCM / WebPush notifications exclusively to recipients
 * who are offline or backgrounded (no active foreground WebSocket session).
 */
class PushNotificationService
{
    /**
     * Notify offline/backgrounded recipients of a new chat message.
     *
     * @param  array<int, int>  $recipientUserIds
     * @param  array<string, mixed>  $message
     * @return int Number of push payloads dispatched
     */
    public function notifyOfflineRecipients(
        array $recipientUserIds,
        string $senderName,
        array $message,
        ?string $adTitle = null
    ): int {
        if (empty($recipientUserIds)) {
            return 0;
        }

        $timeoutThreshold = now()->subSeconds((int) config('chat.presence_timeout_seconds', 30));

        // Filter to users who are offline (or whose heartbeat expired)
        $onlineIds = DB::table('chat_user_presence')
            ->whereIn('user_id', $recipientUserIds)
            ->where('status', 'online')
            ->where('last_heartbeat_at', '>=', $timeoutThreshold)
            ->pluck('user_id')
            ->map(fn ($id): int => (int) $id)
            ->all();

        $offlineIds = array_values(array_diff($recipientUserIds, $onlineIds));
        if (empty($offlineIds)) {
            return 0;
        }

        $tokens = DB::table('chat_push_tokens')
            ->whereIn('user_id', $offlineIds)
            ->where('is_active', true)
            ->get();

        if ($tokens->isEmpty()) {
            return 0;
        }

        $preview = $this->formatPreview($message);
        $title = $adTitle !== null && trim($adTitle) !== ''
            ? "{$senderName} · {$adTitle}"
            : $senderName;

        $dispatched = 0;
        $fcmKey = (string) config('chat.push.fcm_server_key', '');
        $fcmEndpoint = (string) config('chat.push.fcm_endpoint', '');

        foreach ($tokens as $tokenRow) {
            $payload = [
                'message' => [
                    'token' => (string) $tokenRow->token,
                    'notification' => [
                        'title' => $title,
                        'body' => $preview,
                    ],
                    'data' => [
                        'channel_id' => (string) ($message['channel_id'] ?? ''),
                        'message_id' => (string) ($message['message_id'] ?? ''),
                        'sender_id' => (string) ($message['sender_id'] ?? ''),
                        'type' => (string) ($message['type'] ?? 'text'),
                    ],
                ],
            ];

            if ($fcmKey !== '' && $fcmEndpoint !== '') {
                try {
                    Http::withToken($fcmKey)
                        ->timeout(4)
                        ->post($fcmEndpoint, $payload);
                    $dispatched++;
                } catch (\Throwable $e) {
                    Log::warning('Chat push notification dispatch failed', [
                        'user_id' => $tokenRow->user_id,
                        'provider' => $tokenRow->provider,
                        'error' => $e->getMessage(),
                    ]);
                }
            } else {
                // Credential-free staging/local mode: record structured delivery intent
                Log::info('Chat push notification queued (dry-run)', [
                    'user_id' => $tokenRow->user_id,
                    'provider' => $tokenRow->provider,
                    'channel_id' => $message['channel_id'] ?? null,
                    'message_id' => $message['message_id'] ?? null,
                ]);
                $dispatched++;
            }
        }

        return $dispatched;
    }

    /**
     * @param  array<string, mixed>  $message
     */
    private function formatPreview(array $message): string
    {
        $type = (string) ($message['type'] ?? 'text');
        if ($type === 'audio') {
            return 'رسالة صوتية';
        }
        if ($type === 'image') {
            return 'صورة';
        }
        $body = trim((string) ($message['body'] ?? ''));
        return mb_strlen($body) > 120 ? mb_substr($body, 0, 117) . '...' : $body;
    }
}
