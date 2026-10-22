<?php

namespace Tests\Feature;

use App\Models\Expense;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ExpenseTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->travelTo(CarbonImmutable::parse('2026-10-22 10:00'));
    }

    public function test_electricity_bill_needs_its_month(): void
    {
        $this->actingAsOwner();

        $this->postJson('/api/expenses', ['category' => 'electricity', 'label' => 'JIRAMA', 'amount' => 62000])
            ->assertJsonValidationErrors('period_month');

        $this->postJson('/api/expenses', [
            'category' => 'electricity',
            'label' => 'JIRAMA octobre',
            'amount' => 62000,
            'period_month' => '2026-10',
            'due_date' => '2026-11-10',
        ])->assertCreated()
            ->assertJsonPath('data.expense_date', '2026-10-22')
            ->assertJsonPath('data.status', 'due');

        $this->postJson('/api/expenses', ['category' => 'transport', 'label' => 'Taxi-brousse', 'amount' => 15000])
            ->assertCreated()
            ->assertJsonPath('data.period_month', null);
    }

    public function test_bills_are_marked_paid_and_overdue_ones_are_flagged(): void
    {
        $this->actingAsOwner();
        $late = Expense::factory()->monthly('2026-09', 60000)->create(['due_date' => '2026-10-10']);

        $this->getJson("/api/expenses/{$late->id}")->assertJsonPath('data.status', 'overdue');

        $this->postJson("/api/expenses/{$late->id}/pay")
            ->assertOk()
            ->assertJsonPath('data.paid_at', '2026-10-22')
            ->assertJsonPath('data.status', 'paid');
    }

    public function test_list_filters_by_month_and_status(): void
    {
        $this->actingAsOwner();
        Expense::factory()->monthly('2026-10', 62000)->create(['expense_date' => '2026-11-03']); // facture d'octobre reçue en novembre
        Expense::factory()->create(['expense_date' => '2026-10-05', 'amount' => 10000, 'paid_at' => '2026-10-05']);
        Expense::factory()->create(['expense_date' => '2026-09-05', 'amount' => 99000]);

        $this->getJson('/api/expenses?month=2026-10')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('summary.total', 72000)
            ->assertJsonPath('summary.unpaid_total', 62000);

        $this->getJson('/api/expenses?status=unpaid')->assertJsonCount(2, 'data');
    }

    public function test_staff_has_no_access_to_expenses(): void
    {
        $this->actingAsStaff();

        $this->getJson('/api/expenses')->assertForbidden();
        $this->postJson('/api/expenses', ['category' => 'transport', 'label' => 'Taxi', 'amount' => 1000])->assertForbidden();
    }
}
