<?php

namespace App\Http\Resources;

use App\Models\SalaryRate;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin SalaryRate */
class SalaryRateResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'employee_id' => $this->employee_id,
            'monthly_amount' => $this->monthly_amount,
            'effective_from' => $this->effective_from->toDateString(),
        ];
    }
}
