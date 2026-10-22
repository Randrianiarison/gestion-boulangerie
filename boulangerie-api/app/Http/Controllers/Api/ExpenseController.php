<?php

namespace App\Http\Controllers\Api;

use App\Enums\ExpenseCategory;
use App\Http\Controllers\Controller;
use App\Http\Requests\ExpenseRequest;
use App\Http\Requests\PayExpenseRequest;
use App\Http\Resources\ExpenseResource;
use App\Models\Expense;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\Rule;

class ExpenseController extends Controller
{
    /** Filtres : ?month=AAAA-MM (date ou mois concerné), ?status=unpaid|paid, ?category=. Non payées en premier. */
    public function index(Request $request): AnonymousResourceCollection
    {
        Gate::authorize('viewAny', Expense::class);

        $request->validate([
            'month' => ['nullable', 'date_format:Y-m'],
            'status' => ['nullable', 'in:paid,unpaid'],
            'category' => ['nullable', Rule::enum(ExpenseCategory::class)],
        ]);

        $expenses = Expense::query()
            ->when($request->filled('month'), function ($query) use ($request) {
                $month = CarbonImmutable::parse($request->input('month').'-01');
                $query->where(fn ($q) => $q
                    ->whereBetween('expense_date', [$month->toDateString(), $month->endOfMonth()->toDateString()])
                    ->orWhere('period_month', $request->input('month')));
            })
            ->when($request->input('status') === 'unpaid', fn ($query) => $query->whereNull('paid_at'))
            ->when($request->input('status') === 'paid', fn ($query) => $query->whereNotNull('paid_at'))
            ->when($request->filled('category'), fn ($query) => $query->where('category', $request->input('category')))
            ->orderByRaw('paid_at is not null')
            ->orderByDesc('expense_date')
            ->orderByDesc('id')
            ->get();

        return ExpenseResource::collection($expenses)->additional(['summary' => [
            'total' => (int) $expenses->sum('amount'),
            'unpaid_total' => (int) $expenses->whereNull('paid_at')->sum('amount'),
        ]]);
    }

    public function store(ExpenseRequest $request): JsonResponse
    {
        $expense = Expense::create([
            ...$request->validated(),
            'expense_date' => $request->validated('expense_date') ?? CarbonImmutable::today(),
            'user_id' => $request->user()->id,
        ]);

        return (new ExpenseResource($expense))->response()->setStatusCode(201);
    }

    public function show(Expense $expense): ExpenseResource
    {
        Gate::authorize('view', $expense);

        return new ExpenseResource($expense);
    }

    public function update(ExpenseRequest $request, Expense $expense): ExpenseResource
    {
        $expense->update($request->validated());

        return new ExpenseResource($expense);
    }

    public function destroy(Expense $expense): Response
    {
        Gate::authorize('delete', $expense);
        $expense->delete();

        return response()->noContent();
    }

    /** Marquer une facture comme payée (aujourd'hui par défaut). */
    public function pay(PayExpenseRequest $request, Expense $expense): ExpenseResource
    {
        $expense->update(['paid_at' => $request->dateOrToday('paid_at')]);

        return new ExpenseResource($expense);
    }
}
