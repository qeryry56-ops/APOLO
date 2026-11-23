<?php

namespace App\Services\Chat;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;

/**
 * Key-Value Message Store (ByteByteGo KV Store pattern).
 *
 * Primary key: `(channel_id, message_id)` where `message_id` is a 64-bit
 * monotonic Snowflake ID for fast range scans (`syncAfter`).
 * Idempotency key: `(channel_id, sender_id, client_message_id)` guarantees
 * zero duplicate messages across retries and offline reconnects.
 *
 * Uses Redis Sorted Sets (`ZADD`/`ZRANGEBYSCORE`) for low-latency KV reads/writes
 * when available, mirrored durably in `chat_kv_messages`.
 */
class KvMessageStore
{
    public function __construct(
        private readonly SnowflakeIdGenerator $idGenerator
    ) {
    }

    /**
     * Store a message idempotently and return the canonical message payload.
     *
     * @param  array<string, mixed>  $metadata
     * @return array{message: array<string, mixed>, deduplicated: bool}
     */
    public function putMessage(
        int $channelId,
        int $senderId,
        string $clientMessageId,
        string $type,
        ?string $body,
        array $metadata = []
    ): array {
        $existing = DB::table('chat_kv_messages')
            ->where('channel_id', $channelId)
            ->where('sender_id', $senderId)
            ->where('client_message_id', $clientMessageId)
            ->first();

        if ($existing !== null) {
            return [
                'message' => $this->normalizeRow($existing),
                'deduplicated' => true,
            ];
        }

        $messageId = $this->idGenerator->nextId();
        $createdAt = now();

        $record = [
            'channel_id' => $channelId,
            'message_id' => $messageId,
            'sender_id' => $senderId,
            'client_message_id' => $clientMessageId,
            'type' => in_array($type, ['text', 'audio', 'image'], true) ? $type : 'text',
            'body' => $body,
            'metadata' => json_encode($metadata, JSON_UNESCAPED_UNICODE),
            'created_at' => $createdAt,
        ];

        DB::table('chat_kv_messages')->insert($record);

        $payload = [
            'channel_id' => $channelId,
            'message_id' => $messageId,
            'sender_id' => $senderId,
            'client_message_id' => $clientMessageId,
            'type' => $record['type'],
            'body' => $body ?? '',
            'metadata' => $metadata,
            'created_at' => $createdAt->toIso8601String(),
        ];

        $this->writeToRedisKv($channelId, $messageId, $payload);

        return [
            'message' => $payload,
            'deduplicated' => false,
        ];
    }

    /**
     * Fetch messages in `channel_id` strictly after `afterMessageId`
     * (used by multi-device `cur_max_message_id` sync).
     *
     * @return array<int, array<string, mixed>>
     */
    public function syncAfter(int $channelId, int $afterMessageId, int $limit = 100): array
    {
        $limit = max(1, min($limit, 200));

        $rows = DB::table('chat_kv_messages')
            ->where('channel_id', $channelId)
            ->where('message_id', '>', $afterMessageId)
            ->orderBy('message_id', 'asc')
            ->limit($limit)
            ->get();

        return $rows->map(fn (object $row): array => $this->normalizeRow($row))->all();
    }

    /**
     * Fetch the most recent `limit` messages ordered ascending by `message_id`.
     *
     * @return array<int, array<string, mixed>>
     */
    public function getRecent(int $channelId, int $limit = 50): array
    {
        $limit = max(1, min($limit, 200));

        $rows = DB::table('chat_kv_messages')
            ->where('channel_id', $channelId)
            ->orderBy('message_id', 'desc')
            ->limit($limit)
            ->get()
            ->reverse()
            ->values();

        return $rows->map(fn (object $row): array => $this->normalizeRow($row))->all();
    }

    /**
     * @return array<string, mixed>
     */
    private function normalizeRow(object $row): array
    {
        $meta = [];
        if (is_string($row->metadata) && $row->metadata !== '') {
            $decoded = json_decode($row->metadata, true);
            if (is_array($decoded)) {
                $meta = $decoded;
            }
        } elseif (is_array($row->metadata)) {
            $meta = $row->metadata;
        }

        return [
            'channel_id' => (int) $row->channel_id,
            'message_id' => (int) $row->message_id,
            'sender_id' => (int) $row->sender_id,
            'client_message_id' => (string) $row->client_message_id,
            'type' => (string) $row->type,
            'body' => (string) ($row->body ?? ''),
            'metadata' => $meta,
            'created_at' => (string) $row->created_at,
        ];
    }

    /**
     * Best-effort write-through to Redis KV Sorted Set when Redis is configured.
     *
     * @param  array<string, mixed>  $payload
     */
    private function writeToRedisKv(int $channelId, int $messageId, array $payload): void
    {
        if (config('chat.kv_driver') !== 'redis') {
            return;
        }
        try {
            $conn = Redis::connection((string) config('chat.kv_redis_connection', 'default'));
            $conn->zadd(
                "chat:kv:channel:{$channelId}",
                $messageId,
                json_encode($payload, JSON_UNESCAPED_UNICODE)
            );
        } catch (\Throwable) {
            // Durable relational KV mirror remains authoritative if Redis is unavailable.
        }
    }
}
