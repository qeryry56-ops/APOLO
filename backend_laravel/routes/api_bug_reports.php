<?php

use App\Http\Controllers\Api\BugReportController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Self-Hosted Technical Bug Reporting Routes (Apolo.ma)
|--------------------------------------------------------------------------
| Drop into `routes/api.php` (Laravel automatically prefixes `routes/api.php`
| with `/api`). Registers both the canonical `/api/support/bug-reports`
| endpoint and `/api/v1/support/bug-reports` alias for staging/versioned clients.
*/

Route::post('/support/bug-reports', [BugReportController::class, 'store'])
    ->middleware('throttle:bug_report_limiter');

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/support/bug-reports/{bugReport}/screenshot', [BugReportController::class, 'showScreenshot'])
        ->whereNumber('bugReport');
});

// Optional v1 alias inside Route::prefix('v1')->group(...) for staging parity
Route::prefix('v1')->group(function () {
    Route::post('/support/bug-reports', [BugReportController::class, 'store'])
        ->middleware('throttle:bug_report_limiter');
});
