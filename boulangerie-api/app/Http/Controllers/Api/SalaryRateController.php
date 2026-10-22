<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\BusinessRuleException;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreSalaryRateRequest;
use App\Http\Resources\SalaryRateResource;
use App\Models\Employee;
use App\Models\SalaryRate;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

class SalaryRateController extends Controller
{
    public function index(Employee $employee): AnonymousResourceCollection
    {
        Gate::authorize('view', $employee);

        return SalaryRateResource::collection($employee->salaryRates);
    }

    /** Changement de salaire à partir d'une date (remplace un changement saisi à la même date). */
    public function store(StoreSalaryRateRequest $request, Employee $employee): JsonResponse
    {
        $rate = $employee->salaryRates()->updateOrCreate(
            ['effective_from' => $request->validated('effective_from')],
            ['monthly_amount' => $request->validated('monthly_amount')],
        );

        return (new SalaryRateResource($rate))->response()->setStatusCode(201);
    }

    public function destroy(SalaryRate $salaryRate): Response
    {
        Gate::authorize('update', $salaryRate->employee);

        if ($salaryRate->employee->salaryRates()->count() <= 1) {
            throw new BusinessRuleException('last_salary_rate', status: 409);
        }

        $salaryRate->delete();

        return response()->noContent();
    }
}
