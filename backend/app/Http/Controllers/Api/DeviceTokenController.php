<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\StoreDeviceTokenRequest;
use App\Models\DeviceToken;
use Illuminate\Support\Facades\Log;

class DeviceTokenController extends Controller
{
    public function store(StoreDeviceTokenRequest $request)
    {
        $data = $request->validated();
        $user = $request->user();

        // A physical device may switch accounts (logout/login as someone
        // else); `token` is globally unique, so drop any stale row owned by
        // a different user before (re)assigning it to this one.
        DeviceToken::query()
            ->where('token', $data['token'])
            ->where('user_id', '!=', $user->id)
            ->delete();

        $deviceToken = $user->deviceTokens()->updateOrCreate(
            ['token' => $data['token']],
            ['platform' => $data['platform']],
        );

        // Best-effort FCM topic subscription based on the caller-supplied
        // (or last known) province/district — never fails the request.
        $provinceId = $data['province_id'] ?? null;
        $districtId = $data['district_id'] ?? null;

        $topics = array_filter([
            $provinceId ? "province_{$provinceId}" : null,
            $districtId ? "district_{$districtId}" : null,
        ]);

        foreach ($topics as $topic) {
            $this->subscribeToTopic($deviceToken->token, $topic);
        }

        return response()->json([
            'data' => [
                'id' => $deviceToken->id,
                'token' => $deviceToken->token,
                'platform' => $deviceToken->platform,
            ],
        ], 201);
    }

    private function subscribeToTopic(string $token, string $topic): void
    {
        try {
            app(\Kreait\Firebase\Contract\Messaging::class)->subscribeToTopic($topic, $token);
        } catch (\Throwable $e) {
            Log::warning('FCM topic subscription failed', ['topic' => $topic, 'error' => $e->getMessage()]);
        }
    }
}
