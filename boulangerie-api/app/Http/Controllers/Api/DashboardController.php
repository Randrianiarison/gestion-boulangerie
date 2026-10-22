<?php

namespace App\Http\Controllers\Api;

use App\Enums\ProductCategory;
use App\Http\Controllers\Controller;
use App\Http\Resources\ExpenseResource;
use App\Http\Resources\IngredientResource;
use App\Http\Resources\StockRowResource;
use App\Http\Resources\WasteRecordResource;
use App\Models\Employee;
use App\Models\Expense;
use App\Models\Ingredient;
use App\Models\WasteRecord;
use App\Services\DayLock;
use App\Services\SalaryCalculator;
use App\Services\StockService;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    /** Jours avant échéance à partir desquels une facture apparaît dans les rappels. */
    private const BILL_REMINDER_DAYS = 7;

    public function __invoke(
        Request $request,
        StockService $stock,
        DayLock $lock,
        SalaryCalculator $salaries,
    ): JsonResponse {
        $today = CarbonImmutable::today();
        $lastClosed = $lock->lastClosedDate();

        $waste = WasteRecord::with('product')->where('date', $today->toDateString())->get();
        $alerts = Ingredient::withStock()
            ->where('active', true)
            ->orderBy('name_fr')
            ->get()
            ->filter->isBelowThreshold()
            ->values();

        $data = [
            'date' => $today->toDateString(),
            'revenue_today' => $this->revenueOn($today),
            'closing' => [
                'closed_today' => $lastClosed?->eq($today) ?? false,
                'last_closed_on' => $lastClosed?->toDateString(),
            ],
            'stock' => StockRowResource::collection($stock->availabilityOn($today, includeEmptyActive: true))->resolve(),
            'waste_today' => [
                'quantity' => (int) $waste->sum('quantity'),
                'lost_value' => (int) $waste->sum(fn (WasteRecord $record) => $record->lostValue()),
                'recovered' => (int) $waste->sum('recovered_amount'),
                'items' => WasteRecordResource::collection($waste)->resolve(),
            ],
            'ingredient_alerts' => IngredientResource::collection($alerts)->resolve(),
        ];

        // Factures et salaires : owner uniquement.
        if ($request->user()->isOwner()) {
            $bills = Expense::unpaid()
                ->where(fn ($query) => $query->whereNull('due_date')
                    ->orWhere('due_date', '<=', $today->addDays(self::BILL_REMINDER_DAYS)->toDateString()))
                ->orderByRaw('due_date is null')
                ->orderBy('due_date')
                ->get();

            $data['bills_due'] = ExpenseResource::collection($bills)->resolve();
            $data['salaries_due_total'] = (int) Employee::with(['salaryRates', 'salaryPayments'])->get()
                ->sum(fn (Employee $employee) => max(0, $salaries->balance($employee, $today)));
        }

        return response()->json(['data' => $data]);
    }

    private function revenueOn(CarbonImmutable $day): array
    {
        $date = $day->toDateString();

        $sales = DB::table('sales')
            ->join('products', 'products.id', '=', 'sales.product_id')
            ->where('sales.sold_on', $date)
            ->groupBy('products.category')
            ->selectRaw('products.category as category, SUM(sales.total) as amount')
            ->pluck('amount', 'category');
        $recovered = (int) DB::table('waste_records')->where('date', $date)->sum('recovered_amount');

        $byCategory = [];
        foreach (ProductCategory::cases() as $category) {
            $byCategory[$category->value] = (int) ($sales[$category->value] ?? 0);
        }

        return [
            'sales' => (int) $sales->sum(),
            'recovered' => $recovered,
            'total' => (int) $sales->sum() + $recovered,
            'by_category' => $byCategory,
        ];
    }
}
