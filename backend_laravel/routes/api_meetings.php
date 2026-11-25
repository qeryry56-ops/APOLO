<?php

use App\Http\Controllers\Api\MeetingController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Real-Time SFU Group Meeting API Routes (LiveKit SFU Control Plane)
|--------------------------------------------------------------------------
| Mount under `/api` (exposes `/api/v1/meetings/*`).
| Never exposes LiveKit API secrets or raw E2EE keys on the server.
*/
Route::prefix('v1/meetings')->group(function (): void {
    // Signed SFU server-to-server webhook endpoint (verified via Authorization JWT + sha256 body hash)
    Route::post('/webhook', [MeetingController::class, 'handleWebhook'])
        ->middleware('throttle:120,1');

    // Authenticated room lifecycle, short-lived SFU JWT issuance, and host moderation
    Route::middleware(['auth:sanctum', 'throttle:60,1'])->group(function (): void {
        Route::post('/', [MeetingController::class, 'createMeeting']);
        Route::get('/{roomCode}', [MeetingController::class, 'showMeeting']);
        Route::post('/{roomCode}/join', [MeetingController::class, 'joinMeeting']);
        Route::post('/{roomCode}/token/refresh', [MeetingController::class, 'refreshToken']);
        Route::post('/{roomCode}/leave', [MeetingController::class, 'leaveMeeting']);
        Route::post('/{roomCode}/moderate', [MeetingController::class, 'moderateParticipant']);
        Route::post('/{roomCode}/end', [MeetingController::class, 'endMeeting']);
    });
});
