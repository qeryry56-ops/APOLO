<?php

return [
    /*
    |--------------------------------------------------------------------------
    | LiveKit SFU Cluster Configuration (Apolo.ma Group Meetings)
    |--------------------------------------------------------------------------
    | Supports both LiveKit Cloud (`wss://<project>.livekit.cloud`) and
    | self-hosted LiveKit SFU clusters (`wss://rtc.apolo.ma`).
    | API keys and secrets MUST stay strictly server-side.
    */
    'ws_url' => env('LIVEKIT_WS_URL', 'wss://rtc.apolo.ma'),
    'http_url' => env('LIVEKIT_HTTP_URL', 'https://rtc.apolo.ma'),
    'api_key' => env('LIVEKIT_API_KEY', ''),
    'api_secret' => env('LIVEKIT_API_SECRET', ''),

    /*
    |--------------------------------------------------------------------------
    | Multi-Region SFU Edge Pool
    |--------------------------------------------------------------------------
    | Routes participants to the closest SFU edge (Casablanca / EU-West) while
    | LiveKit mesh bridges rooms across regions with a single inter-DC hop.
    */
    'regions' => [
        'ma-casablanca' => env('LIVEKIT_WS_URL_MA', env('LIVEKIT_WS_URL', 'wss://rtc.apolo.ma')),
        'eu-west' => env('LIVEKIT_WS_URL_EU', env('LIVEKIT_WS_URL', 'wss://rtc.apolo.ma')),
    ],

    /*
    |--------------------------------------------------------------------------
    | Room Capacity & Token Security Policy
    |--------------------------------------------------------------------------
    */
    'default_max_participants' => (int) env('MEETINGS_DEFAULT_MAX_PARTICIPANTS', 25),
    'hard_max_participants' => (int) env('MEETINGS_HARD_MAX_PARTICIPANTS', 50),
    'empty_timeout_seconds' => (int) env('MEETINGS_EMPTY_TIMEOUT_SECONDS', 300),
    'token_ttl_seconds' => (int) env('MEETINGS_TOKEN_TTL_SECONDS', 900), // 15 minutes
    'webhook_tolerance_seconds' => (int) env('MEETINGS_WEBHOOK_TOLERANCE_SECONDS', 300),

    /*
    |--------------------------------------------------------------------------
    | STUN / TURN / TURNS NAT Traversal Policy
    |--------------------------------------------------------------------------
    | LiveKit embeds an integrated STUN/TURN server authenticated dynamically
    | via the room token. Optional custom ICE servers can also be supplied
    | (e.g., CoTURN over UDP 3478 and TLS 443 for strict carrier/firewall NATs).
    */
    'ice_transport_policy' => env('MEETINGS_ICE_TRANSPORT_POLICY', 'all'), // 'all' (UDP-first) | 'relay'
    'stun_urls' => array_values(array_filter(array_map(
        'trim',
        explode(',', (string) env('MEETINGS_STUN_URLS', 'stun:turn.apolo.ma:3478,stun:stun.l.google.com:19302'))
    ))),
    'turn_domain' => env('MEETINGS_TURN_DOMAIN', 'turn.apolo.ma'),
    'turn_udp_port' => (int) env('MEETINGS_TURN_UDP_PORT', 3478),
    'turn_tls_port' => (int) env('MEETINGS_TURN_TLS_PORT', 443),
    'turn_shared_secret' => env('MEETINGS_TURN_SHARED_SECRET', ''),
    'turn_credential_ttl_seconds' => (int) env('MEETINGS_TURN_CREDENTIAL_TTL', 3600),

    /*
    |--------------------------------------------------------------------------
    | Adaptive Media Policy (SVC + Simulcast + Downlink Protection)
    |--------------------------------------------------------------------------
    */
    'media_defaults' => [
        'preferred_video_codec' => env('MEETINGS_PREFERRED_CODEC', 'vp9'), // vp9 / av1 SVC with h264 simulcast fallback
        'svc_scalability_mode' => env('MEETINGS_SVC_MODE', 'L3T3_KEY'),
        'simulcast_enabled' => (bool) env('MEETINGS_SIMULCAST_ENABLED', true),
        'dynacast_enabled' => (bool) env('MEETINGS_DYNACAST_ENABLED', true),
        'adaptive_stream_enabled' => (bool) env('MEETINGS_ADAPTIVE_STREAM_ENABLED', true),
        'max_visible_video_tiles_per_page' => 6,
    ],
];
