<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    protected $model = User::class;

    public function definition(): array
    {
        return [
            'firebase_uid' => Str::uuid()->toString(),
            'phone' => '+992'.fake()->numerify('#########'),
            'email' => null,
            'password' => null,
            'name' => fake()->name(),
            'role' => 'citizen',
            'preferred_language' => fake()->randomElement(['tg', 'ru', 'en']),
        ];
    }

    public function admin(): static
    {
        return $this->state(fn () => [
            'role' => 'admin',
            'firebase_uid' => null,
            'email' => fake()->unique()->safeEmail(),
            'password' => Hash::make('password'),
        ]);
    }
}
