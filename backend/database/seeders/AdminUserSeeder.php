<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    /**
     * Creates one local-dev admin account. Credentials come from the env
     * (see .env.example: ADMIN_SEED_EMAIL / ADMIN_SEED_PASSWORD) so no
     * secret is ever hardcoded here — change both in every real deployment.
     */
    public function run(): void
    {
        $email = env('ADMIN_SEED_EMAIL', 'admin@safetj.tj');
        $password = env('ADMIN_SEED_PASSWORD', 'ChangeMe!12345');

        User::query()->updateOrCreate(
            ['email' => $email],
            [
                'name' => 'SafeTJ Admin',
                'password' => Hash::make($password),
                'role' => 'admin',
                'preferred_language' => 'en',
            ],
        );
    }
}
