<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_login_with_phone_and_pin_returns_a_token(): void
    {
        User::factory()->owner()->create(['phone' => '0341234567', 'pin' => '2468']);

        $response = $this->postJson('/api/login', ['phone' => '+261 34 12 345 67', 'pin' => '2468']);

        $response->assertOk()
            ->assertJsonPath('data.user.phone', '0341234567')
            ->assertJsonPath('data.user.role', 'owner')
            ->assertJsonStructure(['data' => ['token']]);

        $this->withToken($response->json('data.token'))
            ->getJson('/api/me')
            ->assertOk()
            ->assertJsonPath('data.phone', '0341234567');
    }

    public function test_wrong_pin_is_refused_with_a_translated_message(): void
    {
        User::factory()->create(['phone' => '0341234567', 'pin' => '2468']);

        $this->postJson('/api/login', ['phone' => '0341234567', 'pin' => '0000'])
            ->assertStatus(422)
            ->assertJsonPath('code', 'invalid_credentials')
            ->assertJsonPath('message', 'Numéro de téléphone ou code PIN incorrect.');

        $this->postJson('/api/login', ['phone' => '0341234567', 'pin' => '0000'], ['Accept-Language' => 'mg'])
            ->assertJsonPath('message', 'Diso ny laharana finday na ny kaody PIN.');
    }

    public function test_validation_messages_follow_the_language(): void
    {
        $this->postJson('/api/login', ['phone' => '0341234567'], ['Accept-Language' => 'mg-MG'])
            ->assertStatus(422)
            ->assertJsonPath('code', 'validation')
            ->assertJsonPath('errors.pin.0', 'Tsy maintsy fenoina ny kaody PIN.');

        $this->postJson('/api/login', ['phone' => '0341234567'])
            ->assertJsonPath('errors.pin.0', 'Le champ code PIN est obligatoire.');
    }

    public function test_disabled_account_cannot_log_in(): void
    {
        User::factory()->inactive()->create(['phone' => '0341234567', 'pin' => '2468']);

        $this->postJson('/api/login', ['phone' => '0341234567', 'pin' => '2468'])
            ->assertForbidden()
            ->assertJsonPath('code', 'account_disabled');
    }

    public function test_routes_require_a_token(): void
    {
        $this->getJson('/api/me')
            ->assertUnauthorized()
            ->assertJsonPath('code', 'unauthenticated')
            ->assertJsonPath('message', 'Session expirée : reconnectez-vous.');
    }

    public function test_unknown_routes_answer_in_the_requested_language(): void
    {
        $this->app->setLocale('en'); // comme un .env resté sur la valeur par défaut

        $this->getJson('/api/day-closing/hier', ['Accept-Language' => 'mg'])
            ->assertNotFound()
            ->assertJsonPath('code', 'not_found')
            ->assertJsonPath('message', 'Tsy hita.');
    }

    public function test_logout_revokes_the_token(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('mobile')->plainTextToken;

        $this->withToken($token)->postJson('/api/logout')->assertNoContent();

        $this->assertSame(0, $user->tokens()->count());
    }

    public function test_login_attempts_are_throttled(): void
    {
        User::factory()->create(['phone' => '0341234567', 'pin' => '2468']);

        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/login', ['phone' => '0341234567', 'pin' => '0000'])->assertStatus(422);
        }

        $this->postJson('/api/login', ['phone' => '0341234567', 'pin' => '2468'])
            ->assertStatus(429)
            ->assertJsonPath('code', 'too_many_attempts');
    }
}
