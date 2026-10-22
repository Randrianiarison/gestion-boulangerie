<?php

namespace App\Models;

use App\Casts\DateOnly;
use App\Enums\ExpenseCategory;
use Carbon\CarbonInterface;
use Database\Factories\ExpenseFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Expense extends Model
{
    /** @use HasFactory<ExpenseFactory> */
    use HasFactory;

    protected $fillable = [
        'category',
        'label',
        'amount',
        'expense_date',
        'period_month',
        'due_date',
        'paid_at',
        'user_id',
    ];

    protected function casts(): array
    {
        return [
            'category' => ExpenseCategory::class,
            'amount' => 'integer',
            'expense_date' => DateOnly::class,
            'due_date' => DateOnly::class,
            'paid_at' => DateOnly::class,
        ];
    }

    public function scopeUnpaid(Builder $query): void
    {
        $query->whereNull('paid_at');
    }

    public function isPaid(): bool
    {
        return $this->paid_at !== null;
    }

    /** paid | overdue (échue, non payée) | due (à payer). */
    public function status(CarbonInterface $today): string
    {
        if ($this->isPaid()) {
            return 'paid';
        }

        return $this->due_date !== null && $this->due_date->lt($today) ? 'overdue' : 'due';
    }
}
