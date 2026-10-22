<?php

namespace Tests\Feature;

use App\Models\DayClosing;
use App\Models\Product;
use App\Models\Sale;
use App\Models\StockLot;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProductionAndSalesTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->travelTo(CarbonImmutable::parse('2026-10-22 08:00'));
    }

    public function test_production_creates_lots_expiring_according_to_shelf_life(): void
    {
        $this->actingAsStaff();
        $baguette = Product::factory()->create(['shelf_life_days' => 1]);
        $sandwichBread = Product::factory()->keeps(3)->create();

        $this->postJson('/api/production', ['items' => [
            ['product_id' => $baguette->id, 'quantity' => 50],
            ['product_id' => $sandwichBread->id, 'quantity' => 20],
        ]])->assertCreated()
            ->assertJsonPath('data.0.produced_on', '2026-10-22')
            ->assertJsonPath('data.0.expires_on', '2026-10-22')
            ->assertJsonPath('data.1.expires_on', '2026-10-24')
            ->assertJsonPath('data.1.quantity_remaining', 20);

        $this->getJson('/api/production')->assertOk()->assertJsonCount(2, 'data');
    }

    public function test_stock_is_the_sum_of_non_expired_lots(): void
    {
        $this->actingAsStaff();
        $bread = Product::factory()->keeps(3)->create();
        $this->lot($bread, '2026-10-19', 7);  // expiré le 21
        $this->lot($bread, '2026-10-20', 10); // expire le 22
        $this->lot($bread, '2026-10-22', 20);

        $row = collect($this->getJson('/api/stock')->assertOk()->json('data'))
            ->firstWhere('product.id', $bread->id);

        $this->assertSame(30, $row['available']);
        $this->assertSame(10, $row['expiring']);
        $this->assertSame(7, $row['stale']);
    }

    public function test_counter_sale_consumes_the_oldest_lot_first_at_the_current_price(): void
    {
        $this->actingAsStaff();
        $bread = Product::factory()->keeps(3)->create(['unit_price' => 1000]);
        $old = $this->lot($bread, '2026-10-21', 5);
        $new = $this->lot($bread, '2026-10-22', 20);

        $this->postJson('/api/sales', ['items' => [['product_id' => $bread->id, 'quantity' => 8]]])
            ->assertCreated()
            ->assertJsonPath('data.0.quantity', 8)
            ->assertJsonPath('data.0.unit_price', 1000)
            ->assertJsonPath('data.0.source', 'counter')
            ->assertJsonPath('total', 8000);

        $this->assertSame(0, $old->fresh()->quantity_remaining);
        $this->assertSame(17, $new->fresh()->quantity_remaining);

        // Le prix change ensuite : la vente garde son prix.
        $bread->update(['unit_price' => 1200]);
        $this->assertSame(8000, Sale::first()->total);
    }

    public function test_sale_above_stock_is_refused_and_nothing_is_recorded(): void
    {
        $this->actingAsStaff();
        $bread = Product::factory()->create(['name_fr' => 'Baguette']);
        $juice = Product::factory()->juice()->create();
        $this->lot($bread, '2026-10-22', 10);
        $this->lot($juice, '2026-10-22', 3);

        $this->postJson('/api/sales', ['items' => [
            ['product_id' => $bread->id, 'quantity' => 2],
            ['product_id' => $juice->id, 'quantity' => 5],
        ]])->assertStatus(422)
            ->assertJsonPath('code', 'insufficient_stock')
            ->assertJsonPath('params.available', 3)
            ->assertJsonPath('params.requested', 5);

        $this->assertSame(0, Sale::count());
        $this->assertSame(10, StockLot::where('product_id', $bread->id)->first()->quantity_remaining);
    }

    public function test_same_product_twice_in_one_sale_is_merged(): void
    {
        $this->actingAsStaff();
        $bread = Product::factory()->create(['unit_price' => 500]);
        $this->lot($bread, '2026-10-22', 10);

        $this->postJson('/api/sales', ['items' => [
            ['product_id' => $bread->id, 'quantity' => 2],
            ['product_id' => $bread->id, 'quantity' => 3],
        ]])->assertCreated()->assertJsonCount(1, 'data')->assertJsonPath('total', 2500);
    }

    public function test_nothing_can_be_recorded_on_a_closed_day(): void
    {
        $this->actingAsStaff();
        $bread = Product::factory()->create();
        $this->lot($bread, '2026-10-22', 10);
        DayClosing::create(['date' => '2026-10-22', 'mode' => 'counted']);

        $this->postJson('/api/sales', ['items' => [['product_id' => $bread->id, 'quantity' => 1]]])
            ->assertStatus(422)
            ->assertJsonPath('code', 'day_closed');

        $this->postJson('/api/production', ['produced_on' => '2026-10-20', 'items' => [['product_id' => $bread->id, 'quantity' => 1]]])
            ->assertStatus(422)
            ->assertJsonPath('code', 'period_closed')
            ->assertJsonPath('params.last', '2026-10-22');
    }

    public function test_future_production_is_refused(): void
    {
        $this->actingAsStaff();
        $bread = Product::factory()->create();

        $this->postJson('/api/production', ['produced_on' => '2026-10-23', 'items' => [['product_id' => $bread->id, 'quantity' => 1]]])
            ->assertStatus(422)
            ->assertJsonValidationErrors('produced_on');
    }

    public function test_an_untouched_lot_can_be_deleted_but_not_a_sold_one(): void
    {
        $this->actingAsStaff();
        $bread = Product::factory()->create();
        $typo = $this->lot($bread, '2026-10-22', 500);
        $this->deleteJson("/api/production/{$typo->id}")->assertNoContent();

        $lot = $this->lot($bread, '2026-10-22', 50);
        $this->postJson('/api/sales', ['items' => [['product_id' => $bread->id, 'quantity' => 1]]])->assertCreated();

        $this->deleteJson("/api/production/{$lot->id}")
            ->assertStatus(409)
            ->assertJsonPath('code', 'lot_already_used');
    }

    public function test_sales_can_be_listed_for_a_period(): void
    {
        $this->actingAsStaff();
        $bread = Product::factory()->keeps(5)->create(['unit_price' => 500]);
        $this->lot($bread, '2026-10-20', 50);
        $this->postJson('/api/sales', ['sold_on' => '2026-10-20', 'items' => [['product_id' => $bread->id, 'quantity' => 4]]]);
        $this->postJson('/api/sales', ['items' => [['product_id' => $bread->id, 'quantity' => 6]]]);

        $this->getJson('/api/sales?from=2026-10-20&to=2026-10-22')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('summary.quantity', 10)
            ->assertJsonPath('summary.total', 5000);

        $this->getJson('/api/sales')->assertJsonPath('summary.total', 3000);
    }
}
