<?php

namespace Tests\Feature;

use App\Models\Employee;
use App\Models\Expense;
use App\Models\Ingredient;
use App\Models\Product;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ReportAndDashboardTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->travelTo(CarbonImmutable::parse('2026-10-22 18:00'));
    }

    public function test_owner_gets_the_weekly_report(): void
    {
        $owner = $this->actingAsOwner();
        $bread = Product::factory()->create(['unit_price' => 800]);
        $this->lot($bread, '2026-10-22', 100);
        $this->postJson('/api/sales', ['items' => [['product_id' => $bread->id, 'quantity' => 50]]])->assertCreated();
        Employee::factory()->withSalary(155000)->create(['hired_on' => '2026-01-01']);

        $this->getJson('/api/reports/summary?period=week&date=2026-10-22')
            ->assertOk()
            ->assertJsonPath('data.period.type', 'week')
            ->assertJsonPath('data.period.from', '2026-10-19')
            ->assertJsonPath('data.period.to', '2026-10-25')
            ->assertJsonPath('data.period.partial', true)
            ->assertJsonPath('data.revenue.total', 40000)
            ->assertJsonPath('data.charges.salaries', 4 * 5000) // du lundi 19 à aujourd'hui
            ->assertJsonPath('data.profit', 20000)
            ->assertJsonCount(7, 'data.series');

        $this->getJson('/api/reports/summary?period=year')->assertJsonValidationErrors('period');
    }

    public function test_staff_cannot_see_reports(): void
    {
        $this->actingAsStaff();

        $this->getJson('/api/reports/summary?period=month')->assertForbidden();
    }

    public function test_dashboard_shows_today_and_owner_only_reminders(): void
    {
        $bread = Product::factory()->create(['unit_price' => 500]);
        $this->lot($bread, '2026-10-22', 40);
        Ingredient::factory()->create(['alert_threshold' => 10]); // stock 0 : alerte
        Expense::factory()->monthly('2026-09', 60000)->create(['due_date' => '2026-10-15']); // échue
        Expense::factory()->monthly('2026-10', 62000)->create(['due_date' => '2026-12-15']); // trop loin
        Employee::factory()->withSalary(155000)->create(['hired_on' => '2026-10-01']);

        $this->actingAsStaff();
        $this->postJson('/api/sales', ['items' => [['product_id' => $bread->id, 'quantity' => 10]]])->assertCreated();

        $this->getJson('/api/dashboard')
            ->assertOk()
            ->assertJsonPath('data.revenue_today.total', 5000)
            ->assertJsonPath('data.revenue_today.by_category.bread', 5000)
            ->assertJsonPath('data.closing.closed_today', false)
            ->assertJsonCount(1, 'data.ingredient_alerts')
            ->assertJsonMissingPath('data.bills_due')
            ->assertJsonMissingPath('data.salaries_due_total');

        $this->actingAsOwner();
        $this->getJson('/api/dashboard')
            ->assertJsonCount(1, 'data.bills_due')
            ->assertJsonPath('data.bills_due.0.status', 'overdue')
            ->assertJsonPath('data.salaries_due_total', 22 * 5000);
    }
}
