<?php

namespace App\Services;

final readonly class VerifiedFirebaseUser
{
    public function __construct(
        public string $uid,
        public ?string $phone,
    ) {}
}
