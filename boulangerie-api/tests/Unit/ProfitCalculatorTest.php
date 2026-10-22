<?php

namespace Tests\Unit;

use App\Enums\ExpenseCategory;
use App\Enums\SaleSource;
use App\Enums\WasteReason;
use App\Models\Employee;
use App\Models\Expense;
use App\Models\Ingredient;
use App\Models\IngredientPurchase;
use App\Models\Product;
use App\Models\Sale;
use App\Models\WasteRecord;
use App\Services\ProfitCalculator;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProfitCalculatorTest extends TestCase
{
    use RefreshDatabase;

    private ProfitCalculator $calculator;

    protected function setUp(): void
    {
        parent::setUp();
        $this->calculator = app(ProfitCalculator::class);
    }

    public function test_week_runs_monday_to_sunday_and_month_is_the_calendar_month(): void
    {
        [$from, $to] = $this->calculator->bounds('week', $this->d('2026-10-01')); // un jeudi
        $this->assertSame(['2026-09-28', '2026-10-04'], [$from->toDateString(), $to->toDateString()]);

        [$from, $to] = $this->calculator->bounds('month', $this->d('2026-02-15'));
        $this->assertSame(['2026-02-01', '2026-02-28'], [$from->toDateString(), $to->toDateString()]);
    }

    public function test_monthly_profit_worked_example(): void
    {
        $bread = Product::factory()->create(['unit_price' => 500]);
        $juice = Product::factory()->juice()->create(['unit_price' => 1000]);

        // Recettes : 500 000 (pain) + 200 000 (jus) + 20 000 récupérés sur les invendus.
        $this->sale($bread, '2026-10-10', 1000);
        $this->sale($juice, '2026-10-20', 200);
        $this->sale($bread, '2026-11-01', 50); // hors période
        $this->waste($bread, '2026-10-12', 60, recovered: 20000);

        // Charges.
        $this->purchase('2026-10-03', 150000);
        $this->purchase('2026-09-30', 99000); // hors période
        Expense::factory()->create(['category' => ExpenseCategory::Transport, 'amount' => 30000, 'expense_date' => '2026-10-15']);
        Expense::factory()->monthly('2026-10', 62000)->create(['paid_at' => '2026-11-03']);
        Expense::factory()->monthly('2026-10', 93000, ExpenseCategory::Rent)->create();
        Employee::factory()->withSalary(155000)->create(['hired_on' => '2026-01-01']);
        Employee::factory()->withSalary(155000)->create(['hired_on' => '2026-10-22']); // 10 jours × 5 000

        $report = $this->calculator->summary('month', $this->d('2026-10-01'), today: $this->d('2026-11-05'));

        $this->assertSame(['from' => '2026-10-01', 'to' => '2026-10-31', 'as_of' => '2026-10-31', 'partial' => false, 'type' => 'month'], $report['period']);
        $this->assertSame(700000, $report['revenue']['sales']);
        $this->assertSame(20000, $report['revenue']['recovered']);
        $this->assertSame(720000, $report['revenue']['total']);
        $this->assertSame(['bread' => 520000, 'juice' => 200000], $report['revenue']['by_category']);

        $this->assertSame(150000, $report['charges']['ingredients']);
        $this->assertSame(30000, $report['charges']['expenses']);
        $this->assertSame(155000, $report['charges']['monthly_expenses']);
        $this->assertSame(205000, $report['charges']['salaries']);
        $this->assertSame(540000, $report['charges']['total']);
        $this->assertSame(62000, $report['charges']['expenses_by_category']['electricity']);
        $this->assertSame(93000, $report['charges']['expenses_by_category']['rent']);

        $this->assertSame(180000, $report['profit']);
    }

    public function test_week_straddling_two_months_prorates_monthly_charges(): void
    {
        // Électricité : septembre 60 000 (30 j) et octobre 62 000 (31 j) → 2 000 Ar par jour dans les deux cas.
        Expense::factory()->monthly('2026-09', 60000)->create();
        Expense::factory()->monthly('2026-10', 62000)->create();
        Expense::factory()->monthly('2026-11', 90000)->create(); // hors période
        Employee::factory()->withSalary(186000)->create(['hired_on' => '2026-01-01']);

        $report = $this->calculator->summary('week', $this->d('2026-10-01'), today: $this->d('2026-10-22'));

        // 3 jours de septembre + 4 jours d'octobre.
        $this->assertSame(14000, $report['charges']['monthly_expenses']);
        $this->assertSame(14000, $report['charges']['expenses_by_category']['electricity']);
        // 3 × 6 200 + 4 × 6 000.
        $this->assertSame(42600, $report['charges']['salaries']);
        $this->assertSame(56600, $report['charges']['total']);
        $this->assertSame(-56600, $report['profit']);
    }

    public function test_grouped_salary_payment_does_not_distort_the_month_it_is_paid(): void
    {
        $employee = Employee::factory()->withSalary(120000)->create(['hired_on' => '2026-07-01']);
        // Juillet, août et septembre payés d'un coup le 5 octobre.
        $employee->salaryPayments()->create(['amount' => 360000, 'paid_on' => '2026-10-05']);

        $july = $this->calculator->summary('month', $this->d('2026-07-01'), today: $this->d('2026-11-05'));
        $october = $this->calculator->summary('month', $this->d('2026-10-01'), today: $this->d('2026-11-05'));

        $this->assertSame(120000, $july['charges']['salaries']);
        $this->assertSame(120000, $october['charges']['salaries']);
        $this->assertSame([['employee_id' => $employee->id, 'name' => $employee->name, 'amount' => 120000]], $october['charges']['salaries_by_employee']);
    }

    public function test_current_period_accrues_salaries_and_monthly_charges_only_until_today(): void
    {
        Employee::factory()->withSalary(155000)->create(['hired_on' => '2026-01-01']);
        Expense::factory()->monthly('2026-10', 62000)->create();

        $report = $this->calculator->summary('month', $this->d('2026-10-22'), today: $this->d('2026-10-22'));

        $this->assertTrue($report['period']['partial']);
        $this->assertSame('2026-10-22', $report['period']['as_of']);
        $this->assertSame(110000, $report['charges']['salaries']);         // 22 × 5 000
        $this->assertSame(44000, $report['charges']['monthly_expenses']);  // 22 × 2 000
    }

    public function test_unsold_value_is_informative_and_never_deducted(): void
    {
        $bread = Product::factory()->create(['unit_price' => 500]);
        $this->sale($bread, '2026-10-10', 100);
        $this->waste($bread, '2026-10-10', 10, recovered: 1500);

        $report = $this->calculator->summary('month', $this->d('2026-10-10'), today: $this->d('2026-11-05'));

        $this->assertSame(['quantity' => 10, 'value' => 5000, 'recovered' => 1500], $report['waste']);
        $this->assertSame(51500, $report['revenue']['total']);
        $this->assertSame(0, $report['charges']['total']);
        $this->assertSame(51500, $report['profit']);
    }

    public function test_top_products_are_ranked_by_revenue(): void
    {
        $baguette = Product::factory()->create(['unit_price' => 800]);
        $croissant = Product::factory()->create(['unit_price' => 1500]);
        $juice = Product::factory()->juice()->create(['unit_price' => 1000]);
        $this->sale($baguette, '2026-10-05', 100); // 80 000
        $this->sale($baguette, '2026-10-06', 50);  // +40 000
        $this->sale($croissant, '2026-10-05', 30); // 45 000
        $this->sale($juice, '2026-10-05', 200);    // 200 000

        $top = $this->calculator->summary('month', $this->d('2026-10-01'), today: $this->d('2026-11-05'))['top_products'];

        $this->assertSame([$juice->id, $baguette->id, $croissant->id], array_column($top, 'product_id'));
        $this->assertSame(150, $top[1]['quantity']);
        $this->assertSame(120000, $top[1]['revenue']);
    }

    public function test_series_gives_revenue_and_charges_for_each_day(): void
    {
        $bread = Product::factory()->create(['unit_price' => 500]);
        $this->sale($bread, '2026-10-20', 10);
        $this->purchase('2026-10-21', 30000);
        Employee::factory()->withSalary(155000)->create(['hired_on' => '2026-01-01']);

        $series = $this->calculator->summary('week', $this->d('2026-10-22'), today: $this->d('2026-10-22'))['series'];

        $this->assertCount(7, $series);
        $this->assertSame(['date' => '2026-10-19', 'revenue' => 0, 'charges' => 5000], $series[0]);
        $this->assertSame(['date' => '2026-10-20', 'revenue' => 5000, 'charges' => 5000], $series[1]);
        $this->assertSame(['date' => '2026-10-21', 'revenue' => 0, 'charges' => 35000], $series[2]);
        $this->assertSame(['date' => '2026-10-23', 'revenue' => 0, 'charges' => 0], $series[4]); // futur
    }

    private function sale(Product $product, string $date, int $quantity): void
    {
        Sale::create([
            'product_id' => $product->id,
            'sold_on' => $date,
            'quantity' => $quantity,
            'unit_price' => $product->unit_price,
            'total' => $quantity * $product->unit_price,
            'source' => SaleSource::Counter,
        ]);
    }

    private function waste(Product $product, string $date, int $quantity, int $recovered = 0): void
    {
        WasteRecord::create([
            'product_id' => $product->id,
            'date' => $date,
            'quantity' => $quantity,
            'reason' => WasteReason::Expired,
            'unit_price' => $product->unit_price,
            'recovered_amount' => $recovered,
        ]);
    }

    private function purchase(string $date, int $total): void
    {
        IngredientPurchase::create([
            'ingredient_id' => Ingredient::factory()->create()->id,
            'purchased_on' => $date,
            'quantity' => 10,
            'unit_price' => intdiv($total, 10),
            'total' => $total,
        ]);
    }

    private function d(string $date): CarbonImmutable
    {
        return CarbonImmutable::parse($date);
    }
}
