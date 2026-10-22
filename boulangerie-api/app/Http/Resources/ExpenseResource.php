<?php

namespace App\Http\Resources;

use App\Models\Expense;
use Carbon\CarbonImmutable;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Expense */
class ExpenseResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'category' => $this->category,
            'label' => $this->label,
            'amount' => $this->amount,
            'expense_date' => $this->expense_date->toDateString(),
            'period_month' => $this->period_month,
            'due_date' => $this->due_date?->toDateString(),
            'paid_at' => $this->paid_at?->toDateString(),
            'status' => $this->status(CarbonImmutable::today()),
        ];
    }
}
