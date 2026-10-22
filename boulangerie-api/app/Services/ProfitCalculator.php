<?php

namespace App\Services;

use App\Enums\ExpenseCategory;
use App\Enums\ProductCategory;
use App\Models\Employee;
use App\Models\Expense;
use Carbon\CarbonImmutable;
use Carbon\CarbonInterface;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

/**
 * Bénéfice d'une période en comptabilité d'engagement.
 *
 * Recettes = ventes + montants récupérés sur les invendus.
 * Charges  = achats d'ingrédients (date d'achat)
 *          + dépenses ponctuelles (expense_date)
 *          + charges mensuelles au prorata des jours de la période dans period_month
 *          + salaires acquis jour par jour, payés ou non.
 *
 * Salaires et charges mensuelles ne sont pas comptés au-delà d'aujourd'hui :
 * le mois en cours est comparé à ses recettes à date.
 */
class ProfitCalculator
{
    public function __construct(private readonly SalaryCalculator $salaries) {}

    /**
     * Semaine du lundi au dimanche, ou mois calendaire, contenant $date.
     *
     * @return array{0: CarbonImmutable, 1: CarbonImmutable}
     */
    public function bounds(string $period, CarbonInterface $date): array
    {
        $date = CarbonImmutable::instance($date)->startOfDay();

        return match ($period) {
            'week' => [$date->startOfWeek(CarbonInterface::MONDAY), $date->endOfWeek(CarbonInterface::SUNDAY)->startOfDay()],
            'month' => [$date->startOfMonth(), $date->endOfMonth()->startOfDay()],
            default => throw new InvalidArgumentException("Période inconnue : {$period}"),
        };
    }

    /** Rapport de la semaine ou du mois contenant $date. */
    public function summary(string $period, CarbonInterface $date, ?CarbonInterface $today = null): array
    {
        [$from, $to] = $this->bounds($period, $date);
        $report = $this->compute($from, $to, $today);
        $report['period']['type'] = $period;

        return $report;
    }

    public function compute(CarbonInterface $from, CarbonInterface $to, ?CarbonInterface $today = null): array
    {
        $from = CarbonImmutable::instance($from)->startOfDay();
        $to = CarbonImmutable::instance($to)->startOfDay();
        $today = CarbonImmutable::instance($today ?? now())->startOfDay();
        $accrualEnd = $to->min($today);

        $oneOffExpenses = Expense::query()
            ->whereNull('period_month')
            ->whereBetween('expense_date', $this->range($from, $to))
            ->get();
        $monthlyExpenses = Expense::query()
            ->whereIn('period_month', $this->monthsBetween($from, $to))
            ->get();
        $employees = Employee::with('salaryRates')
            ->employedBetween($from, $to)
            ->orderBy('name')
            ->get();

        $revenue = $this->revenue($from, $to);
        $charges = $this->charges($from, $to, $accrualEnd, $oneOffExpenses, $monthlyExpenses, $employees);

        return [
            'period' => [
                'from' => $from->toDateString(),
                'to' => $to->toDateString(),
                'as_of' => $accrualEnd->toDateString(),
                'partial' => $to->gt($today),
            ],
            'revenue' => $revenue,
            'charges' => $charges,
            'profit' => $revenue['total'] - $charges['total'],
            'top_products' => $this->topProducts($from, $to),
            'waste' => $this->waste($from, $to),
            'series' => $this->series($from, $to, $accrualEnd, $oneOffExpenses, $monthlyExpenses, $employees),
        ];
    }

    /** Part d'une charge mensuelle entre $from et $to : montant × jours couverts / jours du mois. */
    public function monthlyShareExact(Expense $expense, CarbonInterface $from, CarbonInterface $to): float
    {
        $monthStart = CarbonImmutable::parse($expense->period_month.'-01')->startOfDay();
        $start = CarbonImmutable::instance($from)->startOfDay()->max($monthStart);
        $end = CarbonImmutable::instance($to)->startOfDay()->min($monthStart->endOfMonth()->startOfDay());

        if ($start->gt($end)) {
            return 0.0;
        }

        $days = (int) round($start->diffInDays($end)) + 1;

        return $expense->amount * $days / $monthStart->daysInMonth;
    }

    private function revenue(CarbonImmutable $from, CarbonImmutable $to): array
    {
        $sales = DB::table('sales')
            ->join('products', 'products.id', '=', 'sales.product_id')
            ->whereBetween('sales.sold_on', $this->range($from, $to))
            ->groupBy('products.category')
            ->selectRaw('products.category as category, SUM(sales.total) as amount')
            ->pluck('amount', 'category');

        $recovered = DB::table('waste_records')
            ->join('products', 'products.id', '=', 'waste_records.product_id')
            ->whereBetween('waste_records.date', $this->range($from, $to))
            ->groupBy('products.category')
            ->selectRaw('products.category as category, SUM(waste_records.recovered_amount) as amount')
            ->pluck('amount', 'category');

        $byCategory = [];
        foreach (ProductCategory::cases() as $category) {
            $byCategory[$category->value] = (int) ($sales[$category->value] ?? 0) + (int) ($recovered[$category->value] ?? 0);
        }

        $salesTotal = (int) $sales->sum();
        $recoveredTotal = (int) $recovered->sum();

        return [
            'sales' => $salesTotal,
            'recovered' => $recoveredTotal,
            'total' => $salesTotal + $recoveredTotal,
            'by_category' => $byCategory,
        ];
    }

    /**
     * @param  Collection<int, Expense>  $oneOffExpenses
     * @param  Collection<int, Expense>  $monthlyExpenses
     * @param  Collection<int, Employee>  $employees
     */
    private function charges(
        CarbonImmutable $from,
        CarbonImmutable $to,
        CarbonImmutable $accrualEnd,
        Collection $oneOffExpenses,
        Collection $monthlyExpenses,
        Collection $employees,
    ): array {
        $ingredients = (int) DB::table('ingredient_purchases')
            ->whereBetween('purchased_on', $this->range($from, $to))
            ->sum('total');

        $byCategory = array_fill_keys(array_column(ExpenseCategory::cases(), 'value'), 0);

        $oneOffTotal = 0;
        foreach ($oneOffExpenses as $expense) {
            $oneOffTotal += $expense->amount;
            $byCategory[$expense->category->value] += $expense->amount;
        }

        $monthlyTotal = 0;
        foreach ($monthlyExpenses as $expense) {
            $share = (int) round($this->monthlyShareExact($expense, $from, $accrualEnd));
            $monthlyTotal += $share;
            $byCategory[$expense->category->value] += $share;
        }

        $salaryLines = [];
        foreach ($employees as $employee) {
            $amount = $this->salaries->accrued($employee, $from, $accrualEnd);
            if ($amount > 0) {
                $salaryLines[] = ['employee_id' => $employee->id, 'name' => $employee->name, 'amount' => $amount];
            }
        }
        $salaries = array_sum(array_column($salaryLines, 'amount'));

        return [
            'ingredients' => $ingredients,
            'expenses' => $oneOffTotal,
            'monthly_expenses' => $monthlyTotal,
            'salaries' => $salaries,
            'total' => $ingredients + $oneOffTotal + $monthlyTotal + $salaries,
            'expenses_by_category' => $byCategory,
            'salaries_by_employee' => $salaryLines,
        ];
    }

    private function topProducts(CarbonImmutable $from, CarbonImmutable $to, int $limit = 5): array
    {
        return DB::table('sales')
            ->join('products', 'products.id', '=', 'sales.product_id')
            ->whereBetween('sales.sold_on', $this->range($from, $to))
            ->groupBy('sales.product_id', 'products.name_fr', 'products.name_mg', 'products.format', 'products.category')
            ->selectRaw('sales.product_id, products.name_fr, products.name_mg, products.format, products.category,
                SUM(sales.quantity) as quantity, SUM(sales.total) as revenue')
            ->orderByDesc('revenue')
            ->limit($limit)
            ->get()
            ->map(fn ($row) => [
                'product_id' => (int) $row->product_id,
                'name_fr' => $row->name_fr,
                'name_mg' => $row->name_mg,
                'format' => $row->format,
                'category' => $row->category,
                'quantity' => (int) $row->quantity,
                'revenue' => (int) $row->revenue,
            ])
            ->all();
    }

    /** Valeur des invendus au prix de vente : perte de chiffre d'affaires, informative, jamais déduite. */
    private function waste(CarbonImmutable $from, CarbonImmutable $to): array
    {
        $row = DB::table('waste_records')
            ->whereBetween('date', $this->range($from, $to))
            ->selectRaw('COALESCE(SUM(quantity), 0) as quantity, COALESCE(SUM(quantity * unit_price), 0) as value,
                COALESCE(SUM(recovered_amount), 0) as recovered')
            ->first();

        return [
            'quantity' => (int) $row->quantity,
            'value' => (int) $row->value,
            'recovered' => (int) $row->recovered,
        ];
    }

    /**
     * Recettes et charges jour par jour, pour le graphique (arrondi par jour).
     *
     * @param  Collection<int, Expense>  $oneOffExpenses
     * @param  Collection<int, Expense>  $monthlyExpenses
     * @param  Collection<int, Employee>  $employees
     */
    private function series(
        CarbonImmutable $from,
        CarbonImmutable $to,
        CarbonImmutable $accrualEnd,
        Collection $oneOffExpenses,
        Collection $monthlyExpenses,
        Collection $employees,
    ): array {
        $sales = $this->sumByDay('sales', 'sold_on', 'total', $from, $to);
        $recovered = $this->sumByDay('waste_records', 'date', 'recovered_amount', $from, $to);
        $purchases = $this->sumByDay('ingredient_purchases', 'purchased_on', 'total', $from, $to);
        $oneOff = $oneOffExpenses->groupBy(fn (Expense $e) => $e->expense_date->toDateString())
            ->map(fn (Collection $group) => $group->sum('amount'));

        $series = [];
        for ($day = $from; $day->lte($to); $day = $day->addDay()) {
            $key = $day->toDateString();
            $charges = (float) ($purchases[$key] ?? 0) + (float) ($oneOff[$key] ?? 0);

            if ($day->lte($accrualEnd)) {
                foreach ($monthlyExpenses as $expense) {
                    if ($expense->period_month === $day->format('Y-m')) {
                        $charges += $expense->amount / $day->daysInMonth;
                    }
                }
                foreach ($employees as $employee) {
                    $charges += $this->salaries->dailyAmount($employee, $day);
                }
            }

            $series[] = [
                'date' => $key,
                'revenue' => (int) ($sales[$key] ?? 0) + (int) ($recovered[$key] ?? 0),
                'charges' => (int) round($charges),
            ];
        }

        return $series;
    }

    /** @return Collection<string, int|string> */
    private function sumByDay(string $table, string $dateColumn, string $amountColumn, CarbonImmutable $from, CarbonImmutable $to): Collection
    {
        return DB::table($table)
            ->whereBetween($dateColumn, $this->range($from, $to))
            ->groupBy($dateColumn)
            ->selectRaw("{$dateColumn} as day, SUM({$amountColumn}) as amount")
            ->pluck('amount', 'day');
    }

    /** @return list<string> mois 'YYYY-MM' touchés par la période */
    private function monthsBetween(CarbonImmutable $from, CarbonImmutable $to): array
    {
        $months = [];
        for ($month = $from->startOfMonth(); $month->lte($to); $month = $month->addMonth()) {
            $months[] = $month->format('Y-m');
        }

        return $months;
    }

    /** @return array{0: string, 1: string} */
    private function range(CarbonImmutable $from, CarbonImmutable $to): array
    {
        return [$from->toDateString(), $to->toDateString()];
    }
}
