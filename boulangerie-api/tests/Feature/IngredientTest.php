<?php

namespace Tests\Feature;

use App\Models\Ingredient;
use App\Models\IngredientPurchase;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class IngredientTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->travelTo(CarbonImmutable::parse('2026-10-22 10:00'));
    }

    public function test_staff_records_purchases_and_usages_and_stock_follows(): void
    {
        $this->actingAsStaff();
        $flour = Ingredient::factory()->create(['name_fr' => 'Farine', 'alert_threshold' => 25]);

        // 50 kg à 3 300 Ar le kg : le total est calculé.
        $this->postJson('/api/ingredient-purchases', [
            'ingredient_id' => $flour->id,
            'quantity' => 50,
            'unit_price' => 3300,
            'supplier' => 'Marché Analakely',
        ])->assertCreated()
            ->assertJsonPath('data.total', 165000)
            ->assertJsonPath('data.purchased_on', '2026-10-22');

        // 2,5 kg payés 8 500 Ar au total : le prix unitaire est calculé.
        $this->postJson('/api/ingredient-purchases', ['ingredient_id' => $flour->id, 'quantity' => 2.5, 'total' => 8500])
            ->assertCreated()
            ->assertJsonPath('data.unit_price', 3400);

        $this->postJson('/api/ingredient-usages', ['ingredient_id' => $flour->id, 'quantity' => 30])->assertCreated();

        $this->getJson("/api/ingredients/{$flour->id}")
            ->assertOk()
            ->assertJsonPath('data.stock', 22.5)
            ->assertJsonPath('data.low_stock', true)
            ->assertJsonCount(2, 'data.purchases')
            ->assertJsonCount(1, 'data.usages');
    }

    public function test_stock_endpoint_lists_alerts_first(): void
    {
        $this->actingAsStaff();
        $sugar = Ingredient::factory()->create(['name_fr' => 'Sucre', 'alert_threshold' => 10]);
        $flour = Ingredient::factory()->create(['name_fr' => 'Farine', 'alert_threshold' => 5]);
        $this->purchase($sugar, 3);
        $this->purchase($flour, 40);

        $this->getJson('/api/ingredients/stock')
            ->assertOk()
            ->assertJsonPath('alerts_count', 1)
            ->assertJsonPath('data.0.id', $sugar->id)
            ->assertJsonPath('data.0.low_stock', true)
            ->assertJsonPath('data.1.low_stock', false);
    }

    public function test_using_more_than_the_stock_is_refused(): void
    {
        $this->actingAsStaff();
        $butter = Ingredient::factory()->create(['name_fr' => 'Beurre']);
        $this->purchase($butter, 1.5);

        $this->postJson('/api/ingredient-usages', ['ingredient_id' => $butter->id, 'quantity' => 2])
            ->assertStatus(422)
            ->assertJsonPath('code', 'insufficient_ingredient')
            ->assertJsonPath('message', 'Stock insuffisant de Beurre : il reste 1,5 kg.');
    }

    public function test_only_owners_manage_the_ingredient_list(): void
    {
        $this->actingAsStaff();
        $this->postJson('/api/ingredients', ['name_fr' => 'Sel', 'name_mg' => 'Sira', 'unit' => 'kg', 'alert_threshold' => 2])
            ->assertForbidden();

        $this->actingAsOwner();
        $this->postJson('/api/ingredients', ['name_fr' => 'Sel', 'name_mg' => 'Sira', 'unit' => 'kg', 'alert_threshold' => 2])
            ->assertCreated()
            ->assertJsonPath('data.stock', 0);
    }

    public function test_an_ingredient_with_history_cannot_be_deleted(): void
    {
        $this->actingAsOwner();
        $flour = Ingredient::factory()->create();
        $this->purchase($flour, 10);

        $this->deleteJson("/api/ingredients/{$flour->id}")
            ->assertStatus(409)
            ->assertJsonPath('code', 'ingredient_has_history');
    }

    private function purchase(Ingredient $ingredient, float $quantity): void
    {
        IngredientPurchase::create([
            'ingredient_id' => $ingredient->id,
            'purchased_on' => '2026-10-20',
            'quantity' => $quantity,
            'unit_price' => 1000,
            'total' => (int) round($quantity * 1000),
        ]);
    }
}
