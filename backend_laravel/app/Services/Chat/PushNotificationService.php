<?php

namespace App\Services\Chat;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Push Notification Service (FCM HTTP v1 + APNs payload support).
 *
 * Dispatches real mobile notifications to Android / iOS devices via Firebase
 * Cloud Messaging HTTP v1 using either a Firebase Service Account JSON
 * (OAuth2 JWT -> Bearer token) or an explicit `CHAT_FCM_SERVER_KEY`.
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

        $preview = $this->formatPreview($message);
        $title = $adTitle !== null && trim($adTitle) !== ''
            ? "{$senderName} · {$adTitle}"
            : $senderName;

        $data = [
            'channel_id' => (string) ($message['channel_id'] ?? ''),
            'message_id' => (string) ($message['message_id'] ?? ''),
            'sender_id' => (string) ($message['sender_id'] ?? ''),
            'sender_name' => $senderName,
            'type' => (string) ($message['type'] ?? 'message'),
        ];

        $dispatched = 0;
        foreach ($offlineIds as $uid) {
            $dispatched += $this->sendToUser(
                userId: (int) $uid,
                title: $title,
                body: $preview,
                data: $data,
                channelId: 'apolo_messages'
            );
        }

        return $dispatched;
    }

    /**
     * Send a push notification directly to all active devices of a single user.
     *
     * @param  array<string, mixed>  $data
     */
    public function sendToUser(
        int $userId,
        string $title,
        string $body,
        array $data = [],
        string $channelId = 'apolo_alerts'
    ): int {
        if ($userId <= 0) {
            return 0;
        }

        $tokens = DB::table('chat_push_tokens')
            ->where('user_id', $userId)
            ->where('is_active', true)
            ->get();

        if ($tokens->isEmpty()) {
            return 0;
        }

        $stringData = [];
        foreach ($data as $key => $value) {
            $k = (string) $key;
            if ($k === '' || $value === null) {
                continue;
            }
            $stringData[$k] = is_scalar($value) ? (string) $value : (json_encode($value) ?: '');
        }
        $stringData['channel'] = $channelId;

        $dispatched = 0;
        foreach ($tokens as $tokenRow) {
            if ($this->dispatchTokenRow($tokenRow, $title, $body, $stringData, $channelId)) {
                $dispatched++;
            }
        }

        return $dispatched;
    }

    /**
     * @param  object  $tokenRow
     * @param  array<string, string>  $stringData
     */
    private function dispatchTokenRow(
        object $tokenRow,
        string $title,
        string $body,
        array $stringData,
        string $channelId
    ): bool {
        [$fcmEndpoint, $bearerToken] = $this->resolveFcmEndpointAndToken();

        $payload = [
            'message' => [
                'token' => (string) $tokenRow->token,
                'notification' => [
                    'title' => $title,
                    'body' => $body,
                ],
                'data' => $stringData,
                'android' => [
                    'priority' => 'HIGH',
                    'notification' => [
                        'channel_id' => $channelId,
                        'sound' => 'default',
                    ],
                ],
                'apns' => [
                    'headers' => [
                        'apns-priority' => '10',
                    ],
                    'payload' => [
                        'aps' => [
                            'sound' => 'default',
                            'content-available' => 1,
                        ],
                    ],
                ],
            ],
        ];

        if ($bearerToken !== '' && $fcmEndpoint !== '') {
            try {
                $response = Http::withToken($bearerToken)
                    ->timeout(5)
                    ->post($fcmEndpoint, $payload);

                if ($response->status() === 404 || str_contains($response->body(), 'UNREGISTERED')) {
                    DB::table('chat_push_tokens')
                        ->where('id', $tokenRow->id)
                        ->update([
                            'is_active' => false,
                            'updated_at' => now(),
                        ]);
                    return false;
                }

                if ($response->failed()) {
                    Log::warning('FCM v1 push returned error', [
                        'user_id' => $tokenRow->user_id,
                        'status' => $response->status(),
                        'body' => $response->body(),
                    ]);
                    return false;
                }

                return true;
            } catch (\Throwable $e) {
                Log::warning('Chat push notification dispatch failed', [
                    'user_id' => $tokenRow->user_id,
                    'provider' => $tokenRow->provider,
                    'error' => $e->getMessage(),
                ]);
                return false;
            }
        }

        // Credential-free staging/local mode: record structured delivery intent
        Log::info('Chat push notification queued (dry-run)', [
            'user_id' => $tokenRow->user_id,
            'provider' => $tokenRow->provider,
            'channel_id' => $channelId,
            'type' => $stringData['type'] ?? 'alert',
        ]);

        return true;
    }

    /**
     * Resolves FCM HTTP v1 endpoint and OAuth2 Bearer token from a Firebase
     * Service Account JSON when configured, or falls back to static key.
     *
     * @return array{0: string, 1: string}
     */
    private function resolveFcmEndpointAndToken(): array
    {
        $configuredEndpoint = (string) config('chat.push.fcm_endpoint', '');
        $serviceAccount = $this->loadServiceAccountCredentials();

        if ($serviceAccount !== null) {
            $projectId = (string) ($serviceAccount['project_id'] ?? config('chat.push.fcm_project_id', 'apolo-chat-e3ccf'));
            $endpoint = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";
            $token = $this->mintServiceAccountBearerToken($serviceAccount);
            return [$endpoint, $token];
        }

        $staticKey = (string) config('chat.push.fcm_server_key', '');
        return [$configuredEndpoint, $staticKey];
    }

    /**
     * @return array<string, mixed>|null
     */
    private function loadServiceAccountCredentials(): ?array
    {
        $rawJson = trim((string) config('chat.push.fcm_service_account_json', ''));
        if ($rawJson !== '') {
            $decoded = json_decode($rawJson, true);
            if (is_array($decoded) && ! empty($decoded['client_email']) && ! empty($decoded['private_key'])) {
                return $decoded;
            }
        }

        $path = trim((string) config('chat.push.fcm_service_account_path', ''));
        if ($path !== '' && is_file($path) && is_readable($path)) {
            $decoded = json_decode((string) file_get_contents($path), true);
            if (is_array($decoded) && ! empty($decoded['client_email']) && ! empty($decoded['private_key'])) {
                return $decoded;
            }
        }

        return null;
    }

    /**
     * @param  array<string, mixed>  $creds
     */
    private function mintServiceAccountBearerToken(array $creds): string
    {
        $cacheKey = 'apolo_fcm_oauth_token_' . md5((string) $creds['client_email']);
        try {
            return (string) Cache::remember($cacheKey, now()->addMinutes(50), function () use ($creds): string {
                $now = time();
                $header = $this->base64UrlEncode((string) json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
                $claims = $this->base64UrlEncode((string) json_encode([
                    'iss' => $creds['client_email'],
                    'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                    'aud' => 'https://oauth2.googleapis.com/token',
                    'iat' => $now,
                    'exp' => $now + 3600,
                ]));

                $signingInput = "{$header}.{$claims}";
                $signature = '';
                $ok = function_exists('openssl_sign') && openssl_sign(
                    $signingInput,
                    $signature,
                    (string) $creds['private_key'],
                    OPENSSL_ALGO_SHA256
                );
                if (! $ok) {
                    return '';
                }

                $jwt = "{$signingInput}." . $this->base64UrlEncode($signature);
                $res = Http::asForm()->timeout(5)->post('https://oauth2.googleapis.com/token', [
                    'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                    'assertion' => $jwt,
                ]);

                if ($res->successful()) {
                    return (string) ($res->json('access_token') ?? '');
                }
                return '';
            });
        } catch (\Throwable $e) {
            Log::warning('Unable to mint FCM OAuth token', ['error' => $e->getMessage()]);
            return '';
        }
    }

    private function base64UrlEncode(string $raw): string
    {
        return rtrim(strtr(base64_encode($raw), '+/', '-_'), '=');
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
