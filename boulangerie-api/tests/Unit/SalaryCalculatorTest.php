<?php

namespace Tests\Unit;

use App\Models\Employee;
use App\Services\SalaryCalculator;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SalaryCalculatorTest extends TestCase
{
    use RefreshDatabase;

    private SalaryCalculator $calculator;

    protected function setUp(): void
    {
        parent::setUp();
        $this->calculator = new SalaryCalculator;
    }

    public function test_a_full_month_accrues_exactly_the_monthly_salary(): void
    {
        $employee = $this->employee('2026-01-01', ['2026-01-01' => 150000]);

        $this->assertSame(150000, $this->calculator->accrued($employee, $this->d('2026-10-01'), $this->d('2026-10-31')));
        $this->assertSame(150000, $this->calculator->accrued($employee, $this->d('2026-02-01'), $this->d('2026-02-28')));
    }

    public function test_a_day_costs_the_monthly_salary_divided_by_the_days_of_its_month(): void
    {
        $employee = $this->employee('2026-01-01', ['2026-01-01' => 155000]);

        // Octobre : 31 jours → 5 000 Ar ; septembre : 30 jours → 5 166,67 Ar.
        $this->assertEqualsWithDelta(5000.0, $this->calculator->dailyAmount($employee, $this->d('2026-10-15')), 0.0001);
        $this->assertEqualsWithDelta(155000 / 30, $this->calculator->dailyAmount($employee, $this->d('2026-09-15')), 0.0001);
        $this->assertSame(0.0, $this->calculator->dailyAmount($employee, $this->d('2025-12-31')));
    }

    public function test_salary_change_in_the_middle_of_the_month(): void
    {
        // 155 000 Ar jusqu'au 15 octobre, 186 000 Ar à partir du 16 octobre.
        $employee = $this->employee('2026-01-01', ['2026-01-01' => 155000, '2026-10-16' => 186000]);

        // 15 jours × 5 000 + 16 jours × 6 000 = 75 000 + 96 000.
        $this->assertSame(171000, $this->calculator->accrued($employee, $this->d('2026-10-01'), $this->d('2026-10-31')));
        $this->assertSame(155000, $this->calculator->rateOn($employee, $this->d('2026-10-15')));
        $this->assertSame(186000, $this->calculator->rateOn($employee, $this->d('2026-10-16')));
        $this->assertSame(186000, $this->calculator->accrued($employee, $this->d('2026-11-01'), $this->d('2026-11-30')));
    }

    public function test_hiring_in_the_middle_of_the_month(): void
    {
        $employee = $this->employee('2026-10-10', ['2026-10-10' => 155000]);

        // Du 10 au 31 octobre : 22 jours × 5 000.
        $this->assertSame(110000, $this->calculator->accrued($employee, $this->d('2026-10-01'), $this->d('2026-10-31')));
        $this->assertSame(0, $this->calculator->accrued($employee, $this->d('2026-09-01'), $this->d('2026-09-30')));
    }

    public function test_leaving_stops_the_accrual(): void
    {
        $employee = $this->employee('2026-01-01', ['2026-01-01' => 155000], leftOn: '2026-10-20');

        $this->assertSame(100000, $this->calculator->accrued($employee, $this->d('2026-10-01'), $this->d('2026-10-31')));
        $this->assertSame(0, $this->calculator->accrued($employee, $this->d('2026-11-01'), $this->d('2026-11-30')));
        $this->assertSame(155000, $this->calculator->currentRate($employee, $this->d('2026-12-01')));
    }

    public function test_week_straddling_two_months_uses_the_length_of_each_month(): void
    {
        // Semaine du lundi 28 septembre au dimanche 4 octobre 2026, salaire 186 000 Ar :
        // septembre (30 j) → 6 200 Ar/jour, octobre (31 j) → 6 000 Ar/jour.
        $employee = $this->employee('2026-01-01', ['2026-01-01' => 186000]);

        // 3 × 6 200 + 4 × 6 000 = 18 600 + 24 000.
        $this->assertSame(42600, $this->calculator->accrued($employee, $this->d('2026-09-28'), $this->d('2026-10-04')));
    }

    public function test_grouped_payment_of_several_months(): void
    {
        $employee = $this->employee('2026-07-01', ['2026-07-01' => 120000]);

        // Fin septembre, rien n'a été versé : juillet, août et septembre sont dus.
        $this->assertSame(360000, $this->calculator->balance($employee, $this->d('2026-09-30')));
        $this->assertSame(3.0, $this->calculator->unpaidMonths($employee, $this->d('2026-09-30')));

        // Paiement groupé des trois mois le 5 octobre.
        $employee->salaryPayments()->create(['amount' => 360000, 'paid_on' => '2026-10-05']);
        $employee->load('salaryPayments');

        // La veille, le paiement n'existe pas encore : 360 000 + 4 × 120 000 / 31 (15 483,87).
        $this->assertSame(375484, $this->calculator->balance($employee, $this->d('2026-10-04')));
        // Après le paiement, seuls les 5 premiers jours d'octobre restent dus : 5 × 120 000 / 31.
        $this->assertSame(19355, $this->calculator->balance($employee, $this->d('2026-10-05')));
        // Les salaires acquis par mois ne bougent pas : le paiement n'est qu'un flux de trésorerie.
        $this->assertSame(120000, $this->calculator->accrued($employee, $this->d('2026-07-01'), $this->d('2026-07-31')));
        $this->assertSame(120000, $this->calculator->accrued($employee, $this->d('2026-10-01'), $this->d('2026-10-31')));
    }

    public function test_paying_more_than_accrued_is_an_advance(): void
    {
        $employee = $this->employee('2026-10-01', ['2026-10-01' => 155000]);
        $employee->salaryPayments()->create(['amount' => 100000, 'paid_on' => '2026-10-05']);
        $employee->load('salaryPayments');

        // 10 jours acquis (50 000) - 100 000 versés.
        $this->assertSame(-50000, $this->calculator->balance($employee, $this->d('2026-10-10')));
        $this->assertSame(0.0, $this->calculator->unpaidMonths($employee, $this->d('2026-10-10')));
    }

    public function test_unpaid_months_is_the_balance_divided_by_the_current_salary(): void
    {
        $employee = $this->employee('2026-08-01', ['2026-08-01' => 155000]);

        // Août + septembre + 15 jours d'octobre = 155 000 + 155 000 + 75 000.
        $summary = $this->calculator->summary($employee, $this->d('2026-10-15'));

        $this->assertSame(385000, $summary['accrued']);
        $this->assertSame(0, $summary['paid']);
        $this->assertSame(385000, $summary['balance']);
        $this->assertSame(155000, $summary['current_rate']);
        $this->assertSame(2.5, $summary['unpaid_months']); // 385 000 / 155 000 = 2,48
    }

    public function test_no_salary_rate_means_nothing_accrues(): void
    {
        $employee = $this->employee('2026-10-01', []);

        $summary = $this->calculator->summary($employee, $this->d('2026-10-31'));

        $this->assertSame(0, $summary['accrued']);
        $this->assertSame(0, $summary['current_rate']);
        $this->assertSame(0.0, $summary['unpaid_months']);
    }

    /**
     * @param  array<string, int>  $rates  effective_from => monthly_amount
     */
    private function employee(string $hiredOn, array $rates, ?string $leftOn = null): Employee
    {
        $employee = Employee::factory()->create(['hired_on' => $hiredOn, 'left_on' => $leftOn]);
        foreach ($rates as $effectiveFrom => $amount) {
            $employee->salaryRates()->create(['effective_from' => $effectiveFrom, 'monthly_amount' => $amount]);
        }

        return $employee->load('salaryRates', 'salaryPayments');
    }

    private function d(string $date): CarbonImmutable
    {
        return CarbonImmutable::parse($date);
    }
}
