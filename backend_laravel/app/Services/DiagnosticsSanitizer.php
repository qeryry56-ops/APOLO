<?php

namespace App\Services;

/**
 * Redacts sensitive tokens, credentials, and oversized structures from
 * user-submitted diagnostics before persisting them to MySQL.
 */
class DiagnosticsSanitizer
{
    private const MAX_DEPTH = 6;
    private const MAX_ARRAY_ITEMS = 200;
    private const MAX_STRING_LENGTH = 1000;

    private const SENSITIVE_KEY_PATTERN =
        '/password|passwd|secret|token|auth|cookie|session|otp|pin|cvv|card|credit|api[_-]?key|private[_-]?key|bearer|jwt|csrf|signature/i';

    private const BASIC_META_ALLOWED_KEYS = [
        'is_rtl',
        'authenticated',
    ];

    /**
     * Restricts device_meta strictly to non-identifying operational flags when
     * the user declined optional diagnostics (`include_logs = false`).
     */
    public function filterBasicDeviceMeta(?array $meta): ?array
    {
        if ($meta === null) {
            return null;
        }

        $filtered = [];
        foreach (self::BASIC_META_ALLOWED_KEYS as $key) {
            if (array_key_exists($key, $meta)) {
                $filtered[$key] = (bool) $meta[$key];
            }
        }

        return $filtered === [] ? null : $filtered;
    }

    /**
     * Recursively redacts sensitive keys/values and enforces depth, item-count,
     * and total serialized byte caps.
     */
    public function sanitize(mixed $data, int $maxBytes = 131072): mixed
    {
        if ($data === null) {
            return null;
        }

        $sanitized = $this->sanitizeNode($data, 0);

        $encoded = json_encode($sanitized, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        if ($encoded !== false && strlen($encoded) > $maxBytes) {
            if (is_array($sanitized)) {
                return [
                    '_truncated' => true,
                    '_reason' => 'Payload exceeded max byte limit',
                    'captured_at' => $sanitized['captured_at'] ?? null,
                    'logs_count' => $sanitized['logs_count'] ?? null,
                    'breadcrumbs_count' => $sanitized['breadcrumbs_count'] ?? null,
                ];
            }

            return $this->truncateString((string) $sanitized, max(256, $maxBytes - 32));
        }

        return $sanitized;
    }

    public function sanitizeString(string $value): string
    {
        $clean = preg_replace('/Bearer\s+[A-Za-z0-9\-._~+\/]+=*/i', 'Bearer [REDACTED]', $value) ?? $value;
        $clean = preg_replace('/\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b/', '[REDACTED_JWT]', $clean) ?? $clean;
        $clean = preg_replace('/(https?:\/\/)([^:\/@\s]+):([^\/@\s]+)@/i', '$1[REDACTED]:[REDACTED]@', $clean) ?? $clean;
        $clean = preg_replace(
            '/([?&](?:token|access_token|refresh_token|api_key|apikey|secret|password|otp|code|auth|signature)=)([^&\s]+)/i',
            '$1[REDACTED]',
            $clean
        ) ?? $clean;
        $clean = preg_replace(
            '/\b(password|passwd|secret|token|otp|pin|cvv|api[_-]?key|authorization|cookie|session|jwt|csrf|signature)\b(\s*[:=]\s*)([^\s,;\[\]}]+)/i',
            '$1$2[REDACTED]',
            $clean
        ) ?? $clean;

        return $this->truncateString(trim($clean), self::MAX_STRING_LENGTH);
    }

    private function sanitizeNode(mixed $node, int $depth): mixed
    {
        if ($node === null || is_bool($node) || is_int($node) || is_float($node)) {
            return $node;
        }

        if (is_string($node)) {
            return $this->sanitizeString($node);
        }

        if (!is_array($node)) {
            return $this->sanitizeString((string) $node);
        }

        if ($depth >= self::MAX_DEPTH) {
            return ['_truncated' => true];
        }

        $out = [];
        $count = 0;
        $isList = array_is_list($node);

        foreach ($node as $key => $value) {
            if ($count >= self::MAX_ARRAY_ITEMS) {
                $out['_truncated_items'] = true;
                break;
            }
            $count++;

            if (!$isList) {
                $cleanKey = $this->truncateString((string) $key, 64);
                if (preg_match(self::SENSITIVE_KEY_PATTERN, $cleanKey) === 1) {
                    $out[$cleanKey] = '[REDACTED]';
                    continue;
                }
                $out[$cleanKey] = $this->sanitizeNode($value, $depth + 1);
            } else {
                $out[] = $this->sanitizeNode($value, $depth + 1);
            }
        }

        return $out;
    }

    private function truncateString(string $value, int $maxLength): string
    {
        if (function_exists('mb_strlen') && function_exists('mb_substr')) {
            if (mb_strlen($value, 'UTF-8') > $maxLength) {
                return mb_substr($value, 0, $maxLength, 'UTF-8') . '...';
            }
            return $value;
        }

        if (strlen($value) > $maxLength) {
            return substr($value, 0, $maxLength) . '...';
        }

        return $value;
    }
}
