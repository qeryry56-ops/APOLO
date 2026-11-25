<?php

namespace App\Services\Meetings;

use RuntimeException;

/**
 * Verifies cryptographic authenticity of incoming LiveKit SFU webhooks:
 * 1. Validates HS256 signature of the `Authorization` JWT using LIVEKIT_API_SECRET
 * 2. Validates `iss` matches LIVEKIT_API_KEY and `exp`/`nbf` window
 * 3. Validates `sha256` claim against the raw HTTP request payload digest
 */
class LiveKitWebhookVerifier
{
    public function __construct(
        private readonly LiveKitTokenService $tokenService
    ) {
    }

    /**
     * @return array<string, mixed>
     */
    public function verifyAndDecode(string $rawBody, ?string $authHeader): array
    {
        if (! $this->tokenService->isConfigured()) {
            throw new RuntimeException('LiveKit credentials are not configured.');
        }

        if ($authHeader === null || trim($authHeader) === '') {
            throw new RuntimeException('Missing Authorization webhook signature.');
        }

        $jwt = preg_replace('/^Bearer\s+/i', '', trim($authHeader)) ?? '';
        $parts = explode('.', $jwt);
        if (count($parts) !== 3) {
            throw new RuntimeException('Invalid webhook JWT structure.');
        }

        [$headerB64, $payloadB64, $sigB64] = $parts;

        $header = json_decode($this->tokenService->base64UrlDecode($headerB64), true);
        if (! is_array($header) || ($header['alg'] ?? '') !== 'HS256') {
            throw new RuntimeException('Unsupported webhook JWT algorithm.');
        }

        $expectedSig = hash_hmac(
            'sha256',
            "{$headerB64}.{$payloadB64}",
            $this->tokenService->apiSecret(),
            true
        );
        $actualSig = $this->tokenService->base64UrlDecode($sigB64);

        if (! hash_equals($expectedSig, $actualSig)) {
            throw new RuntimeException('Invalid webhook JWT signature.');
        }

        $claims = json_decode($this->tokenService->base64UrlDecode($payloadB64), true);
        if (! is_array($claims)) {
            throw new RuntimeException('Invalid webhook JWT claims.');
        }

        if (($claims['iss'] ?? '') !== $this->tokenService->apiKey()) {
            throw new RuntimeException('Webhook JWT issuer mismatch.');
        }

        $now = time();
        $tolerance = max(30, (int) config('meetings.webhook_tolerance_seconds', 300));

        if (isset($claims['exp']) && ((int) $claims['exp'] + $tolerance) < $now) {
            throw new RuntimeException('Webhook JWT has expired.');
        }

        if (isset($claims['nbf']) && ((int) $claims['nbf'] - $tolerance) > $now) {
            throw new RuntimeException('Webhook JWT not yet valid.');
        }

        $claimedSha = (string) ($claims['sha256'] ?? '');
        if ($claimedSha === '') {
            throw new RuntimeException('Missing payload sha256 digest in webhook JWT.');
        }

        $rawHashBin = hash('sha256', $rawBody, true);
        $rawHashHex = bin2hex($rawHashBin);
        $rawHashB64 = base64_encode($rawHashBin);
        $rawHashB64Url = $this->tokenService->base64UrlEncode($rawHashBin);

        $hashMatches = hash_equals($claimedSha, $rawHashB64)
            || hash_equals($claimedSha, $rawHashB64Url)
            || hash_equals(strtolower($claimedSha), $rawHashHex);

        if (! $hashMatches) {
            throw new RuntimeException('Webhook payload sha256 digest mismatch.');
        }

        $decodedEvent = json_decode($rawBody, true);
        if (! is_array($decodedEvent)) {
            throw new RuntimeException('Invalid webhook JSON payload.');
        }

        return $decodedEvent;
    }
}
