<?php

namespace App\Services;

use Kreait\Firebase\Contract\Auth as FirebaseAuth;
use Kreait\Firebase\Exception\Auth\FailedToVerifyToken;

class FirebaseAuthService
{
    /**
     * The `Kreait\Firebase\Contract\Auth` for the default project is bound
     * automatically by kreait/laravel-firebase's service provider.
     */
    public function __construct(private readonly FirebaseAuth $auth) {}

    /**
     * Verifies a Firebase Phone Auth ID token and extracts the identifying
     * claims we need to find-or-create the local user.
     *
     * @throws FailedToVerifyToken
     */
    public function verifyIdToken(string $idToken): VerifiedFirebaseUser
    {
        $verifiedToken = $this->auth->verifyIdToken($idToken);

        $claims = $verifiedToken->claims();

        return new VerifiedFirebaseUser(
            uid: (string) $claims->get('sub'),
            phone: $claims->has('phone_number') ? (string) $claims->get('phone_number') : null,
        );
    }
}
