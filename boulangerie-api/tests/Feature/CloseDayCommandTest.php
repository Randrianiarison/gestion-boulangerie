<?php

namespace Tests\Feature;

use App\Enums\ClosingMode;
use App\Models\DayClosing;
use App\Models\Product;
use App\Models\Sale;
use App\Models\WasteRecord;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CloseDayCommandTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->travelTo(CarbonImmutable::parse('2026-10-23 06:00'));
    }

    public function test_it_closes_yesterday_without_counting_and_is_idempotent(): void
    {
        $baguette = Product::factory()->create();
        $sandwichBread = Product::factory()->keeps(3)->create();
        $this->lot($baguette, '2026-10-22', 12);
        $kept = $this->lot($sandwichBread, '2026-10-22', 20);

        $this->artisan('stock:close-day')
            ->expectsOutput('Journée du 22/10/2026 clôturée : 12 invendu(s) enregistré(s).')
            ->assertSuccessful();

        $closing = DayClosing::sole();
        $this->assertSame('2026-10-22', $closing->date->toDateString());
        $this->assertSame(ClosingMode::Automatic, $closing->mode);
        $this->assertSame(0, Sale::count()); // sans comptage, rien n'est réputé vendu
        $this->assertSame(12, WasteRecord::sum('quantity'));
        $this->assertSame(20, $kept->fresh()->quantity_remaining);

        $this->artisan('stock:close-day 2026-10-22')
            ->expectsOutput('Journée du 22/10/2026 déjà clôturée : rien à faire.')
            ->assertSuccessful();
        $this->artisan('stock:close-day 2026-10-20')->assertSuccessful();

        $this->assertSame(1, DayClosing::count());
        $this->assertSame(12, WasteRecord::sum('quantity'));
    }

    public function test_it_catches_up_lots_expired_on_forgotten_days(): void
    {
        $baguette = Product::factory()->create();
        $this->lot($baguette, '2026-10-19', 4);
        $this->lot($baguette, '2026-10-20', 6);

        $this->artisan('stock:close-day 2026-10-21')->assertSuccessful();

        $this->assertSame(10, WasteRecord::where('date', '2026-10-21')->sum('quantity'));
    }

    public function test_it_rejects_invalid_and_future_dates(): void
    {
        $this->artisan('stock:close-day 2026-13-01')->assertFailed();
        $this->artisan('stock:close-day 2026-10-24')->assertFailed();
        $this->assertSame(0, DayClosing::count());
    }
}
