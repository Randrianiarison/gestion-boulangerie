<?php

namespace Database\Seeders;

use App\Enums\EmployeeRole;
use App\Enums\ExpenseCategory;
use App\Enums\ProductCategory;
use App\Enums\UserRole;
use App\Models\DayClosing;
use App\Models\Employee;
use App\Models\Expense;
use App\Models\Ingredient;
use App\Models\IngredientUsage;
use App\Models\Product;
use App\Models\User;
use App\Models\WasteRecord;
use App\Services\DayClosingService;
use App\Services\IngredientService;
use App\Services\SaleService;
use App\Services\StockService;
use Carbon\CarbonImmutable;
use Illuminate\Database\Seeder;

/**
 * Trois semaines d'activité fictive pour essayer l'appli :
 * php artisan db:seed --class=DemoDataSeeder
 */
class DemoDataSeeder extends Seeder
{
    private const DAYS = 21;

    public function run(
        StockService $stock,
        SaleService $sales,
        DayClosingService $closings,
        IngredientService $ingredients,
    ): void {
        // Des ventes fictives fausseraient les vrais rapports.
        if (app()->isProduction()) {
            $this->command?->error('Données de démo refusées en production.');

            return;
        }

        $this->call(DatabaseSeeder::class);

        if (DayClosing::exists()) {
            $this->command?->warn('Des clôtures existent déjà : données de démo non ajoutées.');

            return;
        }

        mt_srand(2026);
        $owner = User::where('role', UserRole::Owner)->firstOrFail();
        $today = CarbonImmutable::today();
        $start = $today->subDays(self::DAYS);

        $this->seedEmployees($today);
        $this->seedExpenses($today);
        $this->seedIngredientPurchases($ingredients, $start, $today, $owner);

        $products = Product::active()->get();
        for ($day = $start; $day->lt($today); $day = $day->addDay()) {
            $this->produce($stock, $products, $day, $owner);

            // Quelques ventes au comptoir dans la journée…
            $counter = $products->random(3)
                ->map(fn (Product $p) => ['product_id' => $p->id, 'quantity' => min(mt_rand(2, 6), $stock->available($p, $day))])
                ->filter(fn (array $item) => $item['quantity'] > 0)
                ->values()
                ->all();
            if ($counter !== []) {
                $sales->recordCounterSales($day, $counter, $owner);
            }

            // … puis le comptage du soir : il reste 2 à 12 % du disponible.
            $counts = $stock->availabilityOn($day)
                ->map(fn (array $row) => [
                    'product_id' => $row['product']->id,
                    'remaining' => (int) round($row['available'] * mt_rand(2, 12) / 100),
                ])
                ->all();
            $closing = $closings->close($day, $counts, $owner);

            // Les baguettes de la veille revendues à moitié prix, un jour sur deux.
            WasteRecord::where('day_closing_id', $closing->id)->get()
                ->filter(fn (WasteRecord $record) => mt_rand(0, 1) === 1)
                ->each(fn (WasteRecord $record) => $record->update([
                    'recovered_amount' => intdiv($record->quantity * $record->unit_price, 2),
                ]));

            $this->useIngredients($day);
        }

        // Production de ce matin, pas encore clôturée.
        $this->produce($stock, $products, $today, $owner);
    }

    private function produce(StockService $stock, $products, CarbonImmutable $day, User $owner): void
    {
        foreach ($products as $product) {
            // Les produits qui se gardent ne sont refaits que quand il en manque.
            if ($product->shelf_life_days > 1 && $stock->available($product, $day) >= 8) {
                continue;
            }

            $base = match (true) {
                $product->category === ProductCategory::Juice => 8,
                $product->shelf_life_days > 1 => 20,
                $product->unit_price < 500 => 150,
                default => 90,
            };

            $stock->produce($product, (int) round($base * mt_rand(85, 115) / 100), $day, $owner);
        }
    }

    private function seedEmployees(CarbonImmutable $today): void
    {
        $hery = Employee::create([
            'name' => 'Hery',
            'phone' => '0331234567',
            'role' => EmployeeRole::Preparation,
            'hired_on' => $today->subMonths(6)->startOfMonth(),
        ]);
        $hery->salaryRates()->create(['monthly_amount' => 180000, 'effective_from' => $hery->hired_on]);
        $hery->salaryRates()->create(['monthly_amount' => 200000, 'effective_from' => $today->startOfMonth()]);
        // Payé chaque mois jusqu'à il y a deux mois.
        for ($month = $hery->hired_on; $month->lt($today->subMonths(2)->startOfMonth()); $month = $month->addMonth()) {
            $hery->salaryPayments()->create([
                'amount' => 180000,
                'paid_on' => $month->addMonth()->addDays(2),
                'note' => 'Salaire '.$month->format('m/Y'),
            ]);
        }

        $voahangy = Employee::create([
            'name' => 'Voahangy',
            'phone' => '0349876543',
            'role' => EmployeeRole::Sales,
            'hired_on' => $today->subMonths(2)->startOfMonth()->addDays(14),
        ]);
        $voahangy->salaryRates()->create(['monthly_amount' => 150000, 'effective_from' => $voahangy->hired_on]);
        $voahangy->salaryPayments()->create([
            'amount' => 50000,
            'paid_on' => $today->subDays(10),
            'note' => 'Avance',
        ]);
    }

    private function seedExpenses(CarbonImmutable $today): void
    {
        $lastMonth = $today->subMonth();

        foreach ([[$lastMonth, 58000, true], [$today, 62000, false]] as [$month, $amount, $paid]) {
            Expense::create([
                'category' => ExpenseCategory::Electricity,
                'label' => 'JIRAMA '.$month->format('m/Y'),
                'amount' => $amount,
                'expense_date' => $month->startOfMonth()->addDays(4),
                'period_month' => $month->format('Y-m'),
                'due_date' => $month->startOfMonth()->addDays(19),
                'paid_at' => $paid ? $month->startOfMonth()->addDays(15) : null,
            ]);
            Expense::create([
                'category' => ExpenseCategory::Rent,
                'label' => 'Loyer '.$month->format('m/Y'),
                'amount' => 250000,
                'expense_date' => $month->startOfMonth(),
                'period_month' => $month->format('Y-m'),
                'due_date' => $month->startOfMonth()->addDays(4),
                'paid_at' => $month->startOfMonth()->addDays(3),
            ]);
        }

        Expense::create([
            'category' => ExpenseCategory::Packaging,
            'label' => 'Sachets et bouteilles',
            'amount' => 35000,
            'expense_date' => $today->subDays(9),
            'paid_at' => $today->subDays(9),
        ]);
        Expense::create([
            'category' => ExpenseCategory::Transport,
            'label' => 'Taxi-be marché',
            'amount' => 6000,
            'expense_date' => $today->subDays(3),
            'paid_at' => $today->subDays(3),
        ]);
    }

    private function seedIngredientPurchases(IngredientService $service, CarbonImmutable $start, CarbonImmutable $today, User $owner): void
    {
        $plan = [
            // name_fr => [quantité par achat, prix unitaire]
            'Farine' => [50, 3300],
            'Huile' => [5, 9000],
            'Beurre' => [4, 28000],
            'Sucre' => [10, 4500],
            'Levure' => [20, 1500],
            'Sel' => [3, 1500],
            'Papaye' => [30, 1500],
            'Avocat' => [40, 800],
            'Ananas' => [20, 2500],
        ];

        $ingredients = Ingredient::whereIn('name_fr', array_keys($plan))->get()->keyBy('name_fr');
        for ($day = $start; $day->lte($today); $day = $day->addDays(7)) {
            foreach ($plan as $name => [$quantity, $unitPrice]) {
                $service->recordPurchase($ingredients[$name], $quantity, $unitPrice, null, $day, 'Marché Analakely', $owner);
            }
        }
    }

    private function useIngredients(CarbonImmutable $day): void
    {
        $daily = ['Farine' => 6.5, 'Huile' => 0.6, 'Beurre' => 0.5, 'Sucre' => 1.2, 'Levure' => 2.6, 'Sel' => 0.3, 'Papaye' => 4, 'Avocat' => 6, 'Ananas' => 3];

        foreach (Ingredient::whereIn('name_fr', array_keys($daily))->get() as $ingredient) {
            IngredientUsage::create([
                'ingredient_id' => $ingredient->id,
                'used_on' => $day,
                'quantity' => $daily[$ingredient->name_fr],
            ]);
        }
    }
}
