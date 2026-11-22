<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Self-Hosted Technical Bug Reporting Settings (Apolo.ma)
    |--------------------------------------------------------------------------
    */

    // Use the private 'local' disk (storage/app) so screenshots are never
    // exposed directly under public/storage.
    'bug_reports_disk' => env('BUG_REPORTS_DISK', 'local'),

    'bug_reports_dir' => env('BUG_REPORTS_DIR', 'private/bug-reports'),

    // Maximum screenshot size in kilobytes (5 MB = 5120 KB).
    'max_screenshot_kb' => (int) env('BUG_REPORTS_MAX_SCREENSHOT_KB', 5120),

    // Maximum serialized byte size for optional diagnostics and device metadata.
    'max_diagnostics_bytes' => (int) env('BUG_REPORTS_MAX_DIAGNOSTICS_BYTES', 131072),
    'max_device_meta_bytes' => (int) env('BUG_REPORTS_MAX_DEVICE_META_BYTES', 16384),

    // Allow both authenticated Sanctum users and guest/unauthenticated bug
    // reports (e.g., login/registration issues). Set false to require login.
    'allow_guests' => (bool) env('BUG_REPORTS_ALLOW_GUESTS', true),
];
