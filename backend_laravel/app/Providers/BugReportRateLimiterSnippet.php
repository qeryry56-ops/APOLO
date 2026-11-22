<?php

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;

/*
|--------------------------------------------------------------------------
| Rate Limiter Snippet for `app/Providers/RouteServiceProvider.php`
|--------------------------------------------------------------------------
| Paste inside `RouteServiceProvider::configureRateLimiting()`.
| Because `POST /api/support/bug-reports` supports optional Sanctum auth,
| `$request->user('sanctum')` inspects the Bearer token without blocking guests.
*/

RateLimiter::for('bug_report_limiter', function (Request $request) {
    $user = $request->user('sanctum');

    if ($user && !empty($user->is_admin)) {
        return Limit::none();
    }

    if ($user) {
        return [
            Limit::perMinute(5)->by('bug_user:' . $user->id),
            Limit::perHour(20)->by('bug_user_hr:' . $user->id),
        ];
    }

    return [
        Limit::perMinute(2)->by('bug_ip:' . $request->ip()),
        Limit::perHour(6)->by('bug_ip_hr:' . $request->ip()),
    ];
});
