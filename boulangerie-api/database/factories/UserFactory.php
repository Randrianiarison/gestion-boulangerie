<?php

namespace Database\Factories;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    /**
     * The current PIN being used by the factory.
     */
    protected static ?string $pin;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'name' => fake()->name(),
            'phone' => '03'.fake()->unique()->numerify('########'),
            'pin' => static::$pin ??= Hash::make('1234'),
            'role' => UserRole::Staff,
            'active' => true,
        ];
    }

    public function owner(): static
    {
        return $this->state(fn () => ['role' => UserRole::Owner]);
    }

    public function staff(): static
    {
        return $this->state(fn () => ['role' => UserRole::Staff]);
    }

    public function inactive(): static
    {
        return $this->state(fn () => ['active' => false]);
    }
}
