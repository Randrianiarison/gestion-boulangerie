<?php

namespace Tests\Feature;

use App\Models\Product;
use App\Models\Sale;
use App\Models\StockLot;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/** Mode hors ligne : l'appli renvoie une opération tant qu'elle n'a pas eu de réponse. */
class IdempotencyTest extends TestCase
{
    use RefreshDatabase;

    private Product $bread;

    protected function setUp(): void
    {
        parent::setUp();
        $this->travelTo(CarbonImmutable::parse('2026-10-22 10:00'));
        $this->bread = Product::factory()->create(['unit_price' => 800]);
        $this->lot($this->bread, '2026-10-22', 20);
    }

    public function test_a_resent_sale_is_recorded_only_once(): void
    {
        $this->actingAsStaff();
        $sale = ['items' => [['product_id' => $this->bread->id, 'quantity' => 3]]];
        $headers = ['Idempotency-Key' => 'vente-0001-aaaa'];

        $first = $this->postJson('/api/sales', $sale, $headers)->assertCreated();
        // La réponse s'est perdue : le téléphone renvoie la même opération.
        $second = $this->postJson('/api/sales', $sale, $headers)
            ->assertCreated()
            ->assertHeader('Idempotent-Replayed', 'true');

        $this->assertSame($first->json(), $second->json());
        $this->assertSame(1, Sale::count());
        $this->assertSame(17, StockLot::sole()->quantity_remaining);
    }

    public function test_different_keys_are_different_sales(): void
    {
        $this->actingAsStaff();
        $sale = ['items' => [['product_id' => $this->bread->id, 'quantity' => 3]]];

        $this->postJson('/api/sales', $sale, ['Idempotency-Key' => 'vente-0001-aaaa'])->assertCreated();
        $this->postJson('/api/sales', $sale, ['Idempotency-Key' => 'vente-0002-bbbb'])->assertCreated();
        $this->postJson('/api/sales', $sale)->assertCreated(); // sans clé : comportement habituel

        $this->assertSame(3, Sale::count());
    }

    public function test_keys_belong_to_each_user(): void
    {
        $sale = ['items' => [['product_id' => $this->bread->id, 'quantity' => 1]]];

        Sanctum::actingAs(User::factory()->create());
        $this->postJson('/api/sales', $sale, ['Idempotency-Key' => 'meme-cle-1234'])->assertCreated();
        Sanctum::actingAs(User::factory()->create());
        $this->postJson('/api/sales', $sale, ['Idempotency-Key' => 'meme-cle-1234'])
            ->assertCreated()
            ->assertHeaderMissing('Idempotent-Replayed');

        $this->assertSame(2, Sale::count());
    }

    public function test_a_refused_sale_can_be_resent_once_the_problem_is_fixed(): void
    {
        $this->actingAsStaff();
        $sale = ['items' => [['product_id' => $this->bread->id, 'quantity' => 30]]];
        $headers = ['Idempotency-Key' => 'vente-hors-ligne-01'];

        $this->postJson('/api/sales', $sale, $headers)
            ->assertStatus(422)
            ->assertJsonPath('code', 'insufficient_stock');

        // La production oubliée est saisie, puis la même vente est renvoyée.
        $this->postJson('/api/production', ['items' => [['product_id' => $this->bread->id, 'quantity' => 15]]])->assertCreated();
        $this->postJson('/api/sales', $sale, $headers)->assertCreated();

        $this->assertSame(1, Sale::count());
    }

    public function test_offline_production_is_recorded_once_with_its_own_date(): void
    {
        $this->actingAsStaff();
        $production = ['produced_on' => '2026-10-21', 'items' => [['product_id' => $this->bread->id, 'quantity' => 40]]];
        $headers = ['Idempotency-Key' => 'production-2026-10-21'];

        $this->postJson('/api/production', $production, $headers)->assertCreated();
        $this->postJson('/api/production', $production, $headers)->assertCreated();

        $this->assertSame(1, StockLot::where('produced_on', '2026-10-21')->count());
    }
}
