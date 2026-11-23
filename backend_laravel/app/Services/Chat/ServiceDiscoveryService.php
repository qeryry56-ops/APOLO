<?php

namespace App\Services\Chat;

use Illuminate\Support\Facades\Cache;

/**
 * Stateless Service Discovery (ByteByteGo ZooKeeper / Registry pattern).
 *
 * Recommends the best Stateful Chat Server hostname(s) for a client based on:
 *  - Node health status
 *  - Region preference
 *  - Active connection load ratio (connections / capacity)
 *  - Deterministic fallback tie-breaking by user ID
 */
class ServiceDiscoveryService
{
    /**
     * @return array<string, mixed>
     */
    public function resolveForUser(int $userId, ?string $preferredRegion = null): array
    {
        $nodes = (array) config('chat.nodes', []);
        $healthyNodes = array_values(array_filter(
            $nodes,
            fn (array $node): bool => ($node['healthy'] ?? true) === true && ! empty($node['ws_url'])
        ));

        if (empty($healthyNodes)) {
            $healthyNodes = [
                [
                    'node_id' => 'chat-fallback-1',
                    'region' => 'ma-casablanca',
                    'ws_url' => 'wss://chat-1.apolo.ma/ws',
                    'presence_ws_url' => 'wss://chat-1.apolo.ma/ws',
                    'capacity' => 50000,
                    'healthy' => true,
                ],
            ];
        }

        usort($healthyNodes, function (array $a, array $b) use ($preferredRegion, $userId): int {
            $aRegionMatch = $preferredRegion !== null && ($a['region'] ?? '') === $preferredRegion ? 0 : 1;
            $bRegionMatch = $preferredRegion !== null && ($b['region'] ?? '') === $preferredRegion ? 0 : 1;
            if ($aRegionMatch !== $bRegionMatch) {
                return $aRegionMatch <=> $bRegionMatch;
            }

            $aLoad = $this->loadRatio($a);
            $bLoad = $this->loadRatio($b);
            if (abs($aLoad - $bLoad) > 0.05) {
                return $aLoad <=> $bLoad;
            }

            // Deterministic tie-break spreads users evenly across nodes
            $aHash = crc32($userId . ':' . ($a['node_id'] ?? ''));
            $bHash = crc32($userId . ':' . ($b['node_id'] ?? ''));
            return $aHash <=> $bHash;
        });

        $primary = $healthyNodes[0];
        $fallbacks = array_values(array_map(
            fn (array $node): array => [
                'node_id' => $node['node_id'],
                'region' => $node['region'] ?? 'default',
                'ws_url' => $node['ws_url'],
            ],
            array_slice($healthyNodes, 1)
        ));

        return [
            'node_id' => $primary['node_id'],
            'region' => $primary['region'] ?? 'default',
            'chat_server_ws_url' => $primary['ws_url'],
            'presence_server_ws_url' => $primary['presence_ws_url'] ?? $primary['ws_url'],
            'fallback_nodes' => $fallbacks,
            'heartbeat_interval_ms' => (int) config('chat.heartbeat_interval_ms', 10000),
            'presence_timeout_seconds' => (int) config('chat.presence_timeout_seconds', 30),
            'max_group_members' => (int) config('chat.max_group_members', 100),
        ];
    }

    public function reportNodeLoad(string $nodeId, int $activeConnections): void
    {
        Cache::put("chat:discovery:load:{$nodeId}", max(0, $activeConnections), now()->addMinutes(2));
    }

    private function loadRatio(array $node): float
    {
        $nodeId = (string) ($node['node_id'] ?? 'unknown');
        $capacity = max(1, (int) ($node['capacity'] ?? 50000));
        $active = (int) Cache::get("chat:discovery:load:{$nodeId}", 0);
        return $active / $capacity;
    }
}
