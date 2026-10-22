<?php

namespace App\Http\Resources;

use App\Models\SalaryPayment;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin SalaryPayment */
class SalaryPaymentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'employee_id' => $this->employee_id,
            'amount' => $this->amount,
            'paid_on' => $this->paid_on->toDateString(),
            'note' => $this->note,
        ];
    }
}
