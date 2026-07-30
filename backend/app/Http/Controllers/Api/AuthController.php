<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\LoginRequest;
use App\Http\Requests\Api\UpdateMeRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Services\FirebaseAuthService;
use Illuminate\Http\Request;
use Kreait\Firebase\Exception\Auth\FailedToVerifyToken;

class AuthController extends Controller
{
    public function __construct(private readonly FirebaseAuthService $firebaseAuth) {}

    public function login(LoginRequest $request)
    {
        try {
            $verified = $this->firebaseAuth->verifyIdToken((string) $request->input('firebase_id_token'));
        } catch (FailedToVerifyToken $e) {
            return response()->json([
                'message' => 'Invalid or expired Firebase ID token.',
                'errors' => ['firebase_id_token' => [$e->getMessage()]],
            ], 401);
        }

        $user = User::query()->firstWhere('firebase_uid', $verified->uid);

        if (! $user && $verified->phone) {
            $user = User::query()->firstWhere('phone', $verified->phone);
        }

        if (! $user) {
            $user = User::create([
                'firebase_uid' => $verified->uid,
                'phone' => $verified->phone,
                'role' => 'citizen',
                'preferred_language' => 'tg',
            ]);
        } elseif (! $user->firebase_uid) {
            // Backfill: a user created some other way (e.g. seeded) is now
            // confirmed to own this Firebase identity.
            $user->update(['firebase_uid' => $verified->uid]);
        }

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'data' => [
                'token' => $token,
                'user' => new UserResource($user),
            ],
        ]);
    }

    public function me(Request $request)
    {
        return response()->json([
            'data' => new UserResource($request->user()),
        ]);
    }

    public function updateMe(UpdateMeRequest $request)
    {
        $user = $request->user();
        $user->update($request->validated());

        return response()->json([
            'data' => new UserResource($user),
        ]);
    }
}
