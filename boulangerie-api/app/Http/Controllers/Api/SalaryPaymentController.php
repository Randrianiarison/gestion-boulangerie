<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreSalaryPaymentRequest;
use App\Http\Resources\SalaryPaymentResource;
use App\Models\Employee;
use App\Models\SalaryPayment;
use App\Services\SalaryCalculator;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

class SalaryPaymentController extends Controller
{
    public function index(Employee $employee): AnonymousResourceCollection
    {
        Gate::authorize('view', $employee);

        return SalaryPaymentResource::collection($employee->salaryPayments);
    }

    /** Paiement libre (un mois, plusieurs mois, ou avance) ; renvoie le nouveau solde. */
    public function store(StoreSalaryPaymentRequest $request, Employee $employee, SalaryCalculator $salaries): JsonResponse
    {
        $payment = $employee->salaryPayments()->create([
            'amount' => $request->validated('amount'),
            'paid_on' => $request->dateOrToday('paid_on'),
            'note' => $request->validated('note'),
            'user_id' => $request->user()->id,
        ]);

        $employee->load(['salaryRates', 'salaryPayments']);

        return (new SalaryPaymentResource($payment))
            ->additional(['balance' => $salaries->summary($employee, CarbonImmutable::today())])
            ->response()
            ->setStatusCode(201);
    }

    public function destroy(SalaryPayment $salaryPayment): Response
    {
        Gate::authorize('update', $salaryPayment->employee);
        $salaryPayment->delete();

        return response()->noContent();
    }
}
