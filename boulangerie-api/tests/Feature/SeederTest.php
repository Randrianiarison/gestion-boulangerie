<?php

namespace Tests\Feature;

use App\Enums\UserRole;
use App\Models\DayClosing;
use App\Models\Ingredient;
use App\Models\Product;
use App\Models\User;
use Database\Seeders\DemoDataSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Hash;
use RuntimeException;
use Tests\TestCase;

class SeederTest extends TestCase
{
    use RefreshDatabase;

    public function test_local_seed_creates_demo_accounts_and_catalogue(): void
    {
        $this->seed();

        $this->assertTrue(User::where('phone', '0340000001')->where('role', UserRole::Owner)->exists());
        $this->assertTrue(User::where('phone', '0340000002')->where('role', UserRole::Staff)->exists());
        $this->assertSame(10, Product::count());
        $this->assertSame(9, Ingredient::count());
    }

    public function test_production_seed_refuses_to_run_without_owner_credentials(): void
    {
        $this->app->detectEnvironment(fn () => 'production');
        config(['boulangerie.seed_owner' => ['name' => 'Propriétaire', 'phone' => null, 'pin' => null]]);

        $this->expectException(RuntimeException::class);
        $this->seedInProduction();
    }

    public function test_production_seed_creates_only_the_configured_owner(): void
    {
        $this->app->detectEnvironment(fn () => 'production');
        config(['boulangerie.seed_owner' => ['name' => 'Neny', 'phone' => '034 11 222 33', 'pin' => '4821']]);

        $this->seedInProduction();

        $owner = User::sole();
        $this->assertSame('0341122233', $owner->phone);
        $this->assertSame(UserRole::Owner, $owner->role);
        $this->assertTrue(Hash::check('4821', $owner->pin));
        $this->assertSame(10, Product::count());

        // Relancer le seed ne remet pas l'ancien PIN si le propriétaire l'a changé.
        $owner->update(['pin' => '9090']);
        $this->seedInProduction();
        $this->assertTrue(Hash::check('9090', $owner->fresh()->pin));
    }

    public function test_demo_data_is_refused_in_production(): void
    {
        $this->app->detectEnvironment(fn () => 'production');

        $this->seedInProduction(DemoDataSeeder::class);

        $this->assertSame(0, User::count());
        $this->assertSame(0, DayClosing::count());
    }

    /** Comme sur le serveur : en production, db:seed demande --force. */
    private function seedInProduction(?string $class = null): void
    {
        Artisan::call('db:seed', array_filter(['--class' => $class, '--force' => true]));
    }
}
