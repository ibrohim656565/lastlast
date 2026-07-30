<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DeviceTokenController;
use App\Http\Controllers\Api\EmergencyContactController;
use App\Http\Controllers\Api\IncidentController;
use App\Http\Controllers\Api\ReferenceDataController;
use App\Http\Controllers\Api\SafePointController;
use Illuminate\Support\Facades\Route;

// Per API_CONTRACT.md all mobile JSON endpoints live under /api/v1.
Route::prefix('v1')->group(function () {

    // Public reference/lookup data.
    Route::get('/provinces', [ReferenceDataController::class, 'provinces']);
    Route::get('/districts', [ReferenceDataController::class, 'districts']);
    Route::get('/emergency-contacts', [EmergencyContactController::class, 'index']);

    Route::post('/auth/login', [AuthController::class, 'login']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/auth/me', [AuthController::class, 'me']);
        Route::put('/auth/me', [AuthController::class, 'updateMe']);

        Route::post('/device-tokens', [DeviceTokenController::class, 'store']);

        Route::get('/incidents', [IncidentController::class, 'index']);
        Route::post('/incidents', [IncidentController::class, 'store']);
        Route::post('/incidents/sync', [IncidentController::class, 'sync']);
        Route::get('/incidents/{incident}', [IncidentController::class, 'show']);

        Route::get('/safe-points', [SafePointController::class, 'index']);
    });
});
