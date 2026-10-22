<?php

namespace Tests\Feature;

use App\Models\Employee;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class EmployeeSalaryTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->travelTo(CarbonImmutable::parse('2026-10-15 10:00'));
    }

    public function test_owner_creates_an_employee_with_a_starting_salary(): void
    {
        $this->actingAsOwner();

        $this->postJson('/api/employees', [
            'name' => 'Hery',
            'phone' => '0331234567',
            'role' => 'preparation',
            'hired_on' => '2026-08-01',
            'monthly_amount' => 155000,
        ])->assertCreated()
            ->assertJsonPath('data.salary_rates.0.monthly_amount', 155000)
            ->assertJsonPath('data.salary_rates.0.effective_from', '2026-08-01')
            // Août + septembre + 15 jours d'octobre, rien payé.
            ->assertJsonPath('data.salary.balance', 385000)
            ->assertJsonPath('data.salary.unpaid_months', 2.5);
    }

    public function test_payments_reduce_the_balance_and_can_cover_several_months(): void
    {
        $this->actingAsOwner();
        $employee = Employee::factory()->withSalary(155000)->create(['hired_on' => '2026-08-01']);

        $this->postJson("/api/employees/{$employee->id}/payments", ['amount' => 310000, 'note' => 'Août et septembre'])
            ->assertCreated()
            ->assertJsonPath('data.amount', 310000)
            ->assertJsonPath('data.paid_on', '2026-10-15')
            ->assertJsonPath('balance.balance', 75000)
            ->assertJsonPath('balance.unpaid_months', 0.5);

        // Avance : on paie plus que ce qui est acquis.
        $this->postJson("/api/employees/{$employee->id}/payments", ['amount' => 100000])->assertCreated();

        $this->getJson("/api/employees/{$employee->id}/balance")
            ->assertOk()
            ->assertJsonPath('data.balance', -25000)
            ->assertJsonPath('data.unpaid_months', 0);
    }

    public function test_salary_change_takes_effect_from_its_date(): void
    {
        $this->actingAsOwner();
        $employee = Employee::factory()->withSalary(155000)->create(['hired_on' => '2026-10-01']);

        $this->postJson("/api/employees/{$employee->id}/salary-rates", ['monthly_amount' => 186000, 'effective_from' => '2026-10-11'])
            ->assertCreated();

        // 10 jours × 5 000 + 5 jours × 6 000.
        $this->getJson("/api/employees/{$employee->id}/balance")
            ->assertJsonPath('data.accrued', 80000)
            ->assertJsonPath('data.current_rate', 186000);
    }

    public function test_list_shows_balance_due_for_each_employee(): void
    {
        $this->actingAsOwner();
        Employee::factory()->withSalary(155000)->create(['name' => 'Bako', 'hired_on' => '2026-10-01']);
        Employee::factory()->withSalary(155000)->create(['name' => 'Aina', 'hired_on' => '2026-01-01', 'left_on' => '2026-09-30']);

        $this->getJson('/api/employees')
            ->assertOk()
            ->assertJsonPath('data.0.name', 'Bako') // présents d'abord
            ->assertJsonPath('data.0.salary.balance', 75000)
            ->assertJsonPath('data.1.active', false)
            ->assertJsonPath('total_due', 75000 + 9 * 155000);
    }

    public function test_staff_has_no_access_to_salaries(): void
    {
        $this->actingAsStaff();
        $employee = Employee::factory()->withSalary(155000)->create();

        $this->getJson('/api/employees')->assertForbidden()->assertJsonPath('code', 'forbidden');
        $this->getJson("/api/employees/{$employee->id}/balance")->assertForbidden();
        $this->postJson("/api/employees/{$employee->id}/payments", ['amount' => 1000])->assertForbidden();
        $this->postJson('/api/employees', ['name' => 'X', 'role' => 'sales', 'hired_on' => '2026-10-01', 'monthly_amount' => 1])
            ->assertForbidden();
    }

    public function test_an_employee_who_was_paid_cannot_be_deleted(): void
    {
        $this->actingAsOwner();
        $employee = Employee::factory()->withSalary(155000)->create();
        $employee->salaryPayments()->create(['amount' => 1000, 'paid_on' => '2026-10-01']);

        $this->deleteJson("/api/employees/{$employee->id}")
            ->assertStatus(409)
            ->assertJsonPath('code', 'employee_has_payments');

        $this->putJson("/api/employees/{$employee->id}", ['left_on' => '2026-10-10'])
            ->assertOk()
            ->assertJsonPath('data.left_on', '2026-10-10');
    }

    public function test_departure_cannot_precede_hiring(): void
    {
        $this->actingAsOwner();
        $employee = Employee::factory()->withSalary(155000)->create(['hired_on' => '2026-10-01']);

        $this->putJson("/api/employees/{$employee->id}", ['left_on' => '2026-09-01'])
            ->assertJsonValidationErrors('left_on');
    }
}
