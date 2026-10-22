<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class UserManagementTest extends TestCase
{
    use RefreshDatabase;

    public function test_owner_creates_a_staff_account_that_can_log_in(): void
    {
        $this->actingAsOwner();

        $this->postJson('/api/users', ['name' => 'Fara', 'phone' => '032 11 222 33', 'pin' => '0420', 'role' => 'staff'])
            ->assertCreated()
            ->assertJsonPath('data.phone', '0321122233');

        $this->postJson('/api/login', ['phone' => '0321122233', 'pin' => '0420'])->assertOk();
    }

    public function test_resetting_a_pin_closes_open_sessions(): void
    {
        $this->actingAsOwner();
        $staff = User::factory()->staff()->create();
        $staff->createToken('mobile');

        $this->putJson("/api/users/{$staff->id}", ['pin' => '9999'])->assertOk();

        $this->assertSame(0, $staff->tokens()->count());
    }

    public function test_owner_cannot_lock_themself_out(): void
    {
        $owner = $this->actingAsOwner();

        $this->putJson("/api/users/{$owner->id}", ['active' => false])
            ->assertStatus(422)
            ->assertJsonPath('code', 'cannot_modify_self');
        $this->putJson("/api/users/{$owner->id}", ['role' => 'staff'])
            ->assertJsonPath('code', 'cannot_modify_self');

        // Un autre owner peut en revanche être rétrogradé ou désactivé.
        $other = User::factory()->owner()->create();
        $other->createToken('mobile');
        $this->putJson("/api/users/{$other->id}", ['active' => false])
            ->assertOk()
            ->assertJsonPath('data.active', false);
        $this->assertSame(0, $other->tokens()->count());
    }

    public function test_staff_cannot_manage_accounts(): void
    {
        $this->actingAsStaff();

        $this->getJson('/api/users')->assertForbidden();
    }

    public function test_phone_numbers_are_unique(): void
    {
        $this->actingAsOwner();
        User::factory()->create(['phone' => '0341112233']);

        $this->postJson('/api/users', ['name' => 'X', 'phone' => '+261341112233', 'pin' => '1234', 'role' => 'staff'])
            ->assertJsonValidationErrors('phone');
    }
}
