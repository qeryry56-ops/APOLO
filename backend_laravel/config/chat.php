<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Chat System Scope (ByteByteGo Architecture)
    |--------------------------------------------------------------------------
    | Supports 1-on-1 direct chat and small group chat up to 100 members.
    */
    'max_group_members' => (int) env('CHAT_MAX_GROUP_MEMBERS', 100),

    /*
    |--------------------------------------------------------------------------
    | Snowflake ID Generator Node Identity
    |--------------------------------------------------------------------------
    */
    'datacenter_id' => (int) env('CHAT_DATACENTER_ID', 1),
    'worker_id' => (int) env('CHAT_WORKER_ID', 1),

    /*
    |--------------------------------------------------------------------------
    | Presence Heartbeat Policy
    |--------------------------------------------------------------------------
    */
    'heartbeat_interval_ms' => (int) env('CHAT_HEARTBEAT_INTERVAL_MS', 10000),
    'presence_timeout_seconds' => (int) env('CHAT_PRESENCE_TIMEOUT_SECONDS', 30),

    /*
    |--------------------------------------------------------------------------
    | Stateful Chat & Presence Server Pool (Service Discovery Registry)
    |--------------------------------------------------------------------------
    | Stateless Service Discovery selects the best available Chat Server node
    | by region, health, and active connection load (no single point of failure).
    */
    'nodes' => [
        [
            'node_id' => env('CHAT_NODE_1_ID', 'chat-eu-west-1'),
            'region' => env('CHAT_NODE_1_REGION', 'ma-casablanca'),
            'ws_url' => env('CHAT_NODE_1_WS_URL', 'wss://chat-1.apolo.ma/ws'),
            'presence_ws_url' => env('CHAT_NODE_1_PRESENCE_WS_URL', 'wss://chat-1.apolo.ma/ws'),
            'capacity' => (int) env('CHAT_NODE_1_CAPACITY', 50000),
            'healthy' => true,
        ],
        [
            'node_id' => env('CHAT_NODE_2_ID', 'chat-eu-west-2'),
            'region' => env('CHAT_NODE_2_REGION', 'ma-casablanca'),
            'ws_url' => env('CHAT_NODE_2_WS_URL', 'wss://chat-2.apolo.ma/ws'),
            'presence_ws_url' => env('CHAT_NODE_2_PRESENCE_WS_URL', 'wss://chat-2.apolo.ma/ws'),
            'capacity' => (int) env('CHAT_NODE_2_CAPACITY', 50000),
            'healthy' => true,
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Key-Value Store Configuration (Redis / HBase / Scylla + DB mirror)
    |--------------------------------------------------------------------------
    */
    'kv_driver' => env('CHAT_KV_DRIVER', 'redis'),
    'kv_redis_connection' => env('CHAT_KV_REDIS_CONNECTION', 'default'),

    /*
    |--------------------------------------------------------------------------
    | Third-Party Push Notifications (FCM / APNs for offline/backgrounded users)
    |--------------------------------------------------------------------------
    */
    'push' => [
        'fcm_endpoint' => env('CHAT_FCM_ENDPOINT', 'https://fcm.googleapis.com/v1/projects/apolo-ma/messages:send'),
        'fcm_server_key' => env('CHAT_FCM_SERVER_KEY', ''),
        'apns_endpoint' => env('CHAT_APNS_ENDPOINT', 'https://api.push.apple.com/3/device'),
        'apns_bundle_id' => env('CHAT_APNS_BUNDLE_ID', 'ma.apolo.mobile'),
    ],
];
