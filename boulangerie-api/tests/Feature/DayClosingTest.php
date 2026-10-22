<?php

namespace Tests\Feature;

use App\Enums\SaleSource;
use App\Enums\WasteReason;
use App\Models\DayClosing;
use App\Models\Product;
use App\Models\Sale;
use App\Models\StockLot;
use App\Models\WasteRecord;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DayClosingTest extends TestCase
{
    use RefreshDatabase;

    private Product $baguette;

    private Product $sandwichBread;

    private StockLot $oldSandwich;

    private StockLot $newSandwich;

    protected function setUp(): void
    {
        parent::setUp();
        $this->travelTo(CarbonImmutable::parse('2026-10-22 19:00'));

        // Baguette (1 jour) : 50 produites ce matin, 5 vendues au comptoir.
        $this->baguette = Product::factory()->create(['name_fr' => 'Baguette', 'unit_price' => 800]);
        $this->lot($this->baguette, '2026-10-22', 50)->decrement('quantity_remaining', 5);

        // Pain de mie (3 jours) : 10 restants du lot du 20 (expire ce soir) + 20 du jour.
        $this->sandwichBread = Product::factory()->keeps(3)->create(['name_fr' => 'Pain de mie', 'unit_price' => 3000]);
        $this->oldSandwich = $this->lot($this->sandwichBread, '2026-10-20', 10);
        $this->newSandwich = $this->lot($this->sandwichBread, '2026-10-22', 20);
    }

    public function test_prefill_shows_what_is_available_to_count(): void
    {
        $this->actingAsStaff();

        $response = $this->getJson('/api/day-closing/2026-10-22')
            ->assertOk()
            ->assertJsonPath('data.closed', false)
            ->assertJsonPath('data.can_close', true)
            ->assertJsonPath('data.blocked_reason', null);

        $items = collect($response->json('data.items'))->keyBy('product.id');
        $this->assertSame(45, $items[$this->baguette->id]['available']);
        $this->assertSame(45, $items[$this->baguette->id]['expiring']);
        $this->assertSame(30, $items[$this->sandwichBread->id]['available']);
        $this->assertSame(10, $items[$this->sandwichBread->id]['expiring']);
    }

    public function test_closing_records_sold_as_available_minus_remaining_and_expires_old_lots(): void
    {
        $this->actingAsStaff();

        $response = $this->postJson('/api/day-closing/2026-10-22', ['items' => [
            ['product_id' => $this->baguette->id, 'remaining' => 8, 'recovered_amount' => 2000],
            ['product_id' => $this->sandwichBread->id, 'remaining' => 12],
        ]])->assertCreated()
            ->assertJsonPath('data.closed', true)
            ->assertJsonPath('data.closing.mode', 'counted')
            // 37 baguettes × 800 + 18 pains de mie × 3 000
            ->assertJsonPath('data.closing.sales_total', 37 * 800 + 18 * 3000)
            ->assertJsonPath('data.closing.waste_quantity', 8)
            ->assertJsonPath('data.closing.waste_value', 8 * 800)
            ->assertJsonPath('data.closing.recovered_total', 2000);

        $this->assertSame(37, Sale::where('product_id', $this->baguette->id)->where('source', SaleSource::Closing)->sum('quantity'));

        // Les 8 baguettes restantes expirent ce soir : invendus.
        $waste = WasteRecord::sole();
        $this->assertSame($this->baguette->id, $waste->product_id);
        $this->assertSame(WasteReason::Expired, $waste->reason);
        $this->assertSame(8, $waste->quantity);
        $this->assertSame(2000, $waste->recovered_amount);

        // FIFO : les 18 pains de mie vendus vident d'abord le vieux lot (10) puis 8 du lot du jour.
        $this->assertSame(0, $this->oldSandwich->fresh()->quantity_remaining);
        $this->assertSame(12, $this->newSandwich->fresh()->quantity_remaining);

        // Reportés au lendemain.
        $this->travelTo(CarbonImmutable::parse('2026-10-23 07:00'));
        $tomorrow = collect($this->getJson('/api/stock')->json('data'))->keyBy('product.id');
        $this->assertSame(12, $tomorrow[$this->sandwichBread->id]['available']);
        $this->assertSame(0, $tomorrow[$this->baguette->id]['available']);

        $response->assertJsonPath('data.can_cancel', false); // staff
    }

    public function test_remaining_above_available_is_refused(): void
    {
        $this->actingAsStaff();

        $this->postJson('/api/day-closing/2026-10-22', ['items' => [
            ['product_id' => $this->baguette->id, 'remaining' => 46],
            ['product_id' => $this->sandwichBread->id, 'remaining' => 0],
        ]])->assertStatus(422)
            ->assertJsonPath('code', 'remaining_exceeds_available')
            ->assertJsonPath('params.available', 45)
            ->assertJsonPath('params.remaining', 46);

        $this->assertSame(0, DayClosing::count());
        $this->assertSame(0, Sale::count());
    }

    public function test_every_product_in_stock_must_be_counted(): void
    {
        $this->actingAsStaff();

        $this->postJson('/api/day-closing/2026-10-22', ['items' => [
            ['product_id' => $this->baguette->id, 'remaining' => 0],
        ]])->assertStatus(422)
            ->assertJsonPath('code', 'closing_missing_products')
            ->assertJsonPath('params.products', 'Pain de mie');
    }

    public function test_recovered_amount_needs_unsold_items(): void
    {
        $this->actingAsStaff();

        $this->postJson('/api/day-closing/2026-10-22', ['items' => [
            ['product_id' => $this->baguette->id, 'remaining' => 0],
            ['product_id' => $this->sandwichBread->id, 'remaining' => 5, 'recovered_amount' => 1000],
        ]])->assertStatus(422)->assertJsonPath('code', 'recovered_without_waste');

        $this->assertSame(0, DayClosing::count());
    }

    public function test_days_are_closed_once_and_in_order(): void
    {
        $this->actingAsStaff();
        $counts = ['items' => [
            ['product_id' => $this->baguette->id, 'remaining' => 0],
            ['product_id' => $this->sandwichBread->id, 'remaining' => 0],
        ]];

        $this->postJson('/api/day-closing/2026-10-22', $counts)->assertCreated();

        $this->postJson('/api/day-closing/2026-10-22', $counts)
            ->assertStatus(422)->assertJsonPath('code', 'day_closed');
        $this->postJson('/api/day-closing/2026-10-21', ['items' => []])
            ->assertStatus(422)->assertJsonPath('code', 'period_closed');
        $this->postJson('/api/day-closing/2026-10-23', ['items' => []])
            ->assertStatus(422)->assertJsonPath('code', 'future_date');

        $this->getJson('/api/day-closing/2026-10-21')
            ->assertJsonPath('data.can_close', false)
            ->assertJsonPath('data.blocked_reason', 'period_closed');
        $this->getJson('/api/day-closing/2026-02-30')->assertNotFound();
    }

    public function test_owner_can_cancel_the_last_closing_and_count_again(): void
    {
        $this->actingAsStaff();
        $this->postJson('/api/day-closing/2026-10-22', ['items' => [
            ['product_id' => $this->baguette->id, 'remaining' => 8],
            ['product_id' => $this->sandwichBread->id, 'remaining' => 12],
        ]])->assertCreated();

        $this->deleteJson('/api/day-closing/2026-10-22')->assertForbidden()->assertJsonPath('code', 'forbidden');

        $this->actingAsOwner();
        $this->getJson('/api/day-closing/2026-10-22')->assertJsonPath('data.can_cancel', true);
        $this->deleteJson('/api/day-closing/2026-10-22')
            ->assertOk()
            ->assertJsonPath('data.closed', false)
            ->assertJsonPath('data.can_close', true);

        // Tout est revenu comme avant la clôture (les 5 baguettes vendues au comptoir restent déduites).
        $this->assertSame(0, DayClosing::count());
        $this->assertSame(0, Sale::count());
        $this->assertSame(0, WasteRecord::count());
        $this->assertSame(45, StockLot::where('product_id', $this->baguette->id)->sum('quantity_remaining'));
        $this->assertSame(10, $this->oldSandwich->fresh()->quantity_remaining);
        $this->assertSame(20, $this->newSandwich->fresh()->quantity_remaining);

        // Nouveau comptage.
        $this->postJson('/api/day-closing/2026-10-22', ['items' => [
            ['product_id' => $this->baguette->id, 'remaining' => 3],
            ['product_id' => $this->sandwichBread->id, 'remaining' => 12],
        ]])->assertCreated()->assertJsonPath('data.closing.waste_quantity', 3);
    }

    public function test_cancel_is_blocked_once_the_next_day_has_sales(): void
    {
        $this->actingAsOwner();
        $this->postJson('/api/day-closing/2026-10-22', ['items' => [
            ['product_id' => $this->baguette->id, 'remaining' => 0],
            ['product_id' => $this->sandwichBread->id, 'remaining' => 12],
        ]])->assertCreated();

        $this->travelTo(CarbonImmutable::parse('2026-10-23 09:00'));
        $this->postJson('/api/sales', ['items' => [['product_id' => $this->sandwichBread->id, 'quantity' => 1]]])->assertCreated();

        $this->deleteJson('/api/day-closing/2026-10-22')
            ->assertStatus(422)
            ->assertJsonPath('code', 'closing_has_later_operations');
    }

    public function test_damaged_items_can_be_recorded_by_hand(): void
    {
        $this->actingAsStaff();

        $this->postJson('/api/waste-records', [
            'product_id' => $this->sandwichBread->id,
            'quantity' => 12,
            'reason' => 'damaged',
            'note' => 'Tombés par terre',
        ])->assertCreated()->assertJsonCount(2, 'data'); // 10 du vieux lot + 2 du nouveau

        $this->assertSame(18, StockLot::where('product_id', $this->sandwichBread->id)->sum('quantity_remaining'));

        $this->postJson('/api/waste-records', ['product_id' => $this->baguette->id, 'quantity' => 1, 'reason' => 'expired'])
            ->assertJsonValidationErrors('reason');
    }

    public function test_recovered_amount_can_be_set_later(): void
    {
        $this->actingAsStaff();
        $this->postJson('/api/day-closing/2026-10-22', ['items' => [
            ['product_id' => $this->baguette->id, 'remaining' => 8],
            ['product_id' => $this->sandwichBread->id, 'remaining' => 12],
        ]]);

        $waste = WasteRecord::sole();
        $this->patchJson("/api/waste-records/{$waste->id}", ['recovered_amount' => 1600])
            ->assertOk()
            ->assertJsonPath('data.recovered_amount', 1600)
            ->assertJsonPath('data.lost_value', 6400);
    }
}
