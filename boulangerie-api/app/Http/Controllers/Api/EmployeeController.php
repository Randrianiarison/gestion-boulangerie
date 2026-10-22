<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\BusinessRuleException;
use App\Http\Controllers\Controller;
use App\Http\Requests\EmployeeRequest;
use App\Http\Resources\EmployeeResource;
use App\Models\Employee;
use App\Services\SalaryCalculator;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;

class EmployeeController extends Controller
{
    public function __construct(private readonly SalaryCalculator $salaries) {}

    /** Liste avec solde dû et mois non payés ; les employés partis en dernier. */
    public function index(): AnonymousResourceCollection
    {
        Gate::authorize('viewAny', Employee::class);

        $employees = Employee::with(['salaryRates', 'salaryPayments'])
            ->orderByRaw('left_on is not null')
            ->orderBy('name')
            ->get()
            ->each(function (Employee $employee) {
                $this->withSummary($employee);
                $employee->setRelations([]);
            });

        return EmployeeResource::collection($employees)->additional([
            'total_due' => (int) $employees->sum(fn (Employee $employee) => max(0, $employee->salarySummary['balance'])),
        ]);
    }

    /** Création avec le salaire de départ, en vigueur dès l'embauche. */
    public function store(EmployeeRequest $request): JsonResponse
    {
        $employee = DB::transaction(function () use ($request) {
            $employee = Employee::create($request->safe()->except('monthly_amount'));
            $employee->salaryRates()->create([
                'monthly_amount' => $request->validated('monthly_amount'),
                'effective_from' => $employee->hired_on,
            ]);

            return $employee;
        });

        return $this->detailed($employee)->response()->setStatusCode(201);
    }

    /** Fiche : solde, historique des salaires et des paiements. */
    public function show(Employee $employee): EmployeeResource
    {
        Gate::authorize('view', $employee);

        return $this->detailed($employee);
    }

    public function update(EmployeeRequest $request, Employee $employee): EmployeeResource
    {
        $employee->update($request->validated());

        return $this->detailed($employee);
    }

    /** Seul un employé saisi par erreur (aucun paiement) peut être supprimé ; sinon on renseigne left_on. */
    public function destroy(Employee $employee): Response
    {
        Gate::authorize('delete', $employee);

        if ($employee->salaryPayments()->exists()) {
            throw new BusinessRuleException('employee_has_payments', status: 409);
        }

        $employee->delete();

        return response()->noContent();
    }

    public function balance(Employee $employee): JsonResponse
    {
        Gate::authorize('view', $employee);

        return response()->json(['data' => $this->salaries->summary($employee, CarbonImmutable::today())]);
    }

    private function detailed(Employee $employee): EmployeeResource
    {
        $employee->load(['salaryRates', 'salaryPayments']);

        return new EmployeeResource($this->withSummary($employee));
    }

    private function withSummary(Employee $employee): Employee
    {
        $employee->salarySummary = $this->salaries->summary($employee, CarbonImmutable::today());

        return $employee;
    }
}
