<?php

namespace App\Http\Resources;

use App\Models\Employee;
use Carbon\CarbonImmutable;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Employee */
class EmployeeResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'phone' => $this->phone,
            'role' => $this->role,
            'hired_on' => $this->hired_on->toDateString(),
            'left_on' => $this->left_on?->toDateString(),
            'active' => $this->left_on === null || $this->left_on->gte(CarbonImmutable::today()),
            'salary' => $this->when($this->resource->salarySummary !== null, fn () => $this->resource->salarySummary),
            'salary_rates' => SalaryRateResource::collection($this->whenLoaded('salaryRates')),
            'payments' => SalaryPaymentResource::collection($this->whenLoaded('salaryPayments')),
        ];
    }
}
