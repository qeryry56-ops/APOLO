<?php

use App\Http\Controllers\Api\ChatSystemController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Stateless Chat HTTP API Routes (ByteByteGo Architecture)
|--------------------------------------------------------------------------
| Mount under `/api/v1` behind the load balancer. Real-time bidirectional
| messaging uses WebSockets discovered via `/chat/service-discovery`.
*/
Route::prefix('v1/chat')->group(function () {
    // Service discovery (works with Sanctum token or guest preview)
    Route::get('/service-discovery', [ChatSystemController::class, 'serviceDiscovery']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/channels', [ChatSystemController::class, 'listChannels']);
        Route::post('/channels', [ChatSystemController::class, 'createChannel']);
        Route::post('/channels/{channelId}/members', [ChatSystemController::class, 'addMembers']);
        Route::get('/channels/{channelId}/sync', [ChatSystemController::class, 'syncMessages']);
        Route::post('/channels/{channelId}/messages', [ChatSystemController::class, 'sendMessage']);
        Route::post('/channels/{channelId}/ack', [ChatSystemController::class, 'acknowledgeMessages']);
        Route::post('/push-tokens', [ChatSystemController::class, 'registerPushToken']);
        Route::delete('/push-tokens', [ChatSystemController::class, 'unregisterPushToken']);
        Route::post('/push-notify', [ChatSystemController::class, 'dispatchDirectPush']);
        Route::get('/presence', [ChatSystemController::class, 'getPresence']);
    });
});
