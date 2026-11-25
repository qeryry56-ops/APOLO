<?php

namespace App\Services\Meetings;

use RuntimeException;

/**
 * Mints short-lived LiveKit SFU JWT access tokens (HS256) and ephemeral
 * RFC-5389/5766 STUN/TURN/TURNS credentials without leaking SFU secrets to clients.
 */
class LiveKitTokenService
{
    public function isConfigured(): bool
    {
        return $this->apiKey() !== '' && $this->apiSecret() !== '';
    }

    /**
     * Generates a participant LiveKit AccessToken scoped to a single SFU room.
     *
     * @param  array<string, mixed>  $options
     * @return array{token: string, expires_at: int, ttl_seconds: int}
     */
    public function createParticipantToken(
        string $livekitRoomName,
        string $identity,
        string $displayName,
        array $options = []
    ): array {
        $apiKey = $this->apiKey();
        $apiSecret = $this->apiSecret();

        if ($apiKey === '' || $apiSecret === '') {
            throw new RuntimeException('LiveKit SFU credentials are not configured on the server.');
        }

        $now = time();
        $ttl = max(60, min((int) ($options['ttl_seconds'] ?? config('meetings.token_ttl_seconds', 900)), 3600));
        $exp = $now + $ttl;

        $canPublish = (bool) ($options['can_publish'] ?? true);
        $canSubscribe = (bool) ($options['can_subscribe'] ?? true);
        $canPublishData = (bool) ($options['can_publish_data'] ?? true);
        $isRoomAdmin = (bool) ($options['room_admin'] ?? false);
        $allowScreenShare = (bool) ($options['allow_screen_share'] ?? true);

        $publishSources = ['camera', 'microphone'];
        if ($allowScreenShare) {
            $publishSources[] = 'screen_share';
            $publishSources[] = 'screen_share_audio';
        }

        $videoGrant = [
            'roomJoin' => true,
            'room' => $livekitRoomName,
            'canPublish' => $canPublish,
            'canSubscribe' => $canSubscribe,
            'canPublishData' => $canPublishData,
            'canUpdateOwnMetadata' => true,
            'roomAdmin' => $isRoomAdmin,
        ];

        if ($canPublish) {
            $videoGrant['canPublishSources'] = $publishSources;
        }

        $metadata = $options['metadata'] ?? null;
        $metadataJson = is_array($metadata)
            ? json_encode($metadata, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES)
            : (is_string($metadata) ? $metadata : '');

        $payload = [
            'iss' => $apiKey,
            'sub' => $identity,
            'jti' => bin2hex(random_bytes(12)),
            'iat' => $now,
            'nbf' => $now - 5,
            'exp' => $exp,
            'name' => $displayName,
            'video' => $videoGrant,
        ];

        if ($metadataJson !== '' && $metadataJson !== false) {
            $payload['metadata'] = $metadataJson;
        }

        return [
            'token' => $this->encodeHs256Jwt($payload, $apiSecret),
            'expires_at' => $exp,
            'ttl_seconds' => $ttl,
        ];
    }

    /**
     * Generates a short-lived server-to-server JWT for LiveKit RoomService Twirp RPCs.
     */
    public function createServerAdminToken(?string $livekitRoomName = null, int $ttlSeconds = 120): string
    {
        $apiKey = $this->apiKey();
        $apiSecret = $this->apiSecret();

        if ($apiKey === '' || $apiSecret === '') {
            throw new RuntimeException('LiveKit SFU credentials are not configured on the server.');
        }

        $now = time();
        $videoGrant = [
            'roomCreate' => true,
            'roomList' => true,
            'roomAdmin' => true,
        ];

        if ($livekitRoomName !== null && $livekitRoomName !== '') {
            $videoGrant['room'] = $livekitRoomName;
        }

        $payload = [
            'iss' => $apiKey,
            'sub' => 'apolo-laravel-control-plane',
            'iat' => $now,
            'nbf' => $now - 5,
            'exp' => $now + max(30, $ttlSeconds),
            'video' => $videoGrant,
        ];

        return $this->encodeHs256Jwt($payload, $apiSecret);
    }

    /**
     * Builds ICE servers configuration (STUN + UDP TURN + TLS 443 TURNS fallback)
     * so WebRTC UDP connects cleanly across CGNAT and enterprise firewalls.
     *
     * @return array<int, array<string, mixed>>
     */
    public function buildIceServers(string $participantIdentity): array
    {
        $iceServers = [];

        $stunUrls = (array) config('meetings.stun_urls', []);
        if (! empty($stunUrls)) {
            $iceServers[] = [
                'urls' => array_values($stunUrls),
            ];
        }

        $turnSecret = trim((string) config('meetings.turn_shared_secret', ''));
        $turnDomain = trim((string) config('meetings.turn_domain', ''));

        if ($turnSecret !== '' && $turnDomain !== '') {
            $ttl = max(300, (int) config('meetings.turn_credential_ttl_seconds', 3600));
            $expiresAt = time() + $ttl;
            $username = "{$expiresAt}:{$participantIdentity}";
            $credential = base64_encode(hash_hmac('sha1', $username, $turnSecret, true));

            $udpPort = (int) config('meetings.turn_udp_port', 3478);
            $tlsPort = (int) config('meetings.turn_tls_port', 443);

            $iceServers[] = [
                'urls' => [
                    "turn:{$turnDomain}:{$udpPort}?transport=udp",
                    "turn:{$turnDomain}:{$udpPort}?transport=tcp",
                    "turns:{$turnDomain}:{$tlsPort}?transport=tcp",
                ],
                'username' => $username,
                'credential' => $credential,
            ];
        }

        return $iceServers;
    }

    /**
     * Resolves the optimal regional SFU WebSocket endpoint.
     */
    public function resolveWsUrl(?string $region = null): string
    {
        $regions = (array) config('meetings.regions', []);
        if ($region !== null && isset($regions[$region]) && is_string($regions[$region]) && $regions[$region] !== '') {
            return $regions[$region];
        }

        return (string) config('meetings.ws_url', 'wss://rtc.apolo.ma');
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function encodeHs256Jwt(array $payload, string $secret): string
    {
        $header = [
            'alg' => 'HS256',
            'typ' => 'JWT',
        ];

        $segments = [
            $this->base64UrlEncode((string) json_encode($header, JSON_UNESCAPED_SLASHES)),
            $this->base64UrlEncode((string) json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES)),
        ];

        $signingInput = implode('.', $segments);
        $signature = hash_hmac('sha256', $signingInput, $secret, true);
        $segments[] = $this->base64UrlEncode($signature);

        return implode('.', $segments);
    }

    public function base64UrlEncode(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    public function base64UrlDecode(string $data): string
    {
        $remainder = strlen($data) % 4;
        if ($remainder > 0) {
            $data .= str_repeat('=', 4 - $remainder);
        }

        $decoded = base64_decode(strtr($data, '-_', '+/'), true);
        if ($decoded === false) {
            throw new RuntimeException('Malformed base64url segment.');
        }

        return $decoded;
    }

    public function apiKey(): string
    {
        return trim((string) config('meetings.api_key', ''));
    }

    public function apiSecret(): string
    {
        return trim((string) config('meetings.api_secret', ''));
    }
}
