<?php

namespace App\Services\Chat;

use RuntimeException;

/**
 * 64-bit time-ordered Snowflake ID generator for chat `message_id`.
 *
 * Layout (63 usable positive bits):
 *  - 41 bits: milliseconds since custom epoch (2025-01-01T00:00:00Z)
 *  -  5 bits: datacenter ID (0..31)
 *  -  5 bits: worker ID (0..31)
 *  - 12 bits: per-millisecond sequence (0..4095)
 *
 * Guarantees monotonically sortable IDs across distributed chat servers
 * without any single-point-of-failure database auto-increment lock.
 */
class SnowflakeIdGenerator
{
    private const EPOCH_MS = 1735689600000; // 2025-01-01T00:00:00Z
    private const DATACENTER_BITS = 5;
    private const WORKER_BITS = 5;
    private const SEQUENCE_BITS = 12;

    private const MAX_DATACENTER_ID = (1 << self::DATACENTER_BITS) - 1;
    private const MAX_WORKER_ID = (1 << self::WORKER_BITS) - 1;
    private const SEQUENCE_MASK = (1 << self::SEQUENCE_BITS) - 1;

    private int $datacenterId;
    private int $workerId;
    private int $lastTimestamp = -1;
    private int $sequence = 0;

    public function __construct(?int $datacenterId = null, ?int $workerId = null)
    {
        $this->datacenterId = ($datacenterId ?? (int) config('chat.datacenter_id', 1)) & self::MAX_DATACENTER_ID;
        $this->workerId = ($workerId ?? (int) config('chat.worker_id', 1)) & self::MAX_WORKER_ID;
    }

    public function nextId(): int
    {
        $timestamp = $this->currentTimeMillis();

        if ($timestamp < $this->lastTimestamp) {
            throw new RuntimeException('Clock moved backwards; refusing to generate Snowflake ID.');
        }

        if ($timestamp === $this->lastTimestamp) {
            $this->sequence = ($this->sequence + 1) & self::SEQUENCE_MASK;
            if ($this->sequence === 0) {
                $timestamp = $this->waitNextMillis($this->lastTimestamp);
            }
        } else {
            $this->sequence = 0;
        }

        $this->lastTimestamp = $timestamp;

        return (($timestamp - self::EPOCH_MS) << (self::DATACENTER_BITS + self::WORKER_BITS + self::SEQUENCE_BITS))
            | ($this->datacenterId << (self::WORKER_BITS + self::SEQUENCE_BITS))
            | ($this->workerId << self::SEQUENCE_BITS)
            | $this->sequence;
    }

    private function currentTimeMillis(): int
    {
        return (int) floor(microtime(true) * 1000);
    }

    private function waitNextMillis(int $lastTimestamp): int
    {
        $timestamp = $this->currentTimeMillis();
        while ($timestamp <= $lastTimestamp) {
            usleep(200);
            $timestamp = $this->currentTimeMillis();
        }
        return $timestamp;
    }
}
