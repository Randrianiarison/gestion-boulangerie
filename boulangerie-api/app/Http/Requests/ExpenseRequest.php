<?php

namespace App\Http\Requests;

use App\Enums\ExpenseCategory;
use App\Models\Expense;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/** Création et modification d'une dépense ; period_month obligatoire pour l'électricité et le loyer. */
class ExpenseRequest extends FormRequest
{
    public function authorize(): bool
    {
        $expense = $this->route('expense');

        return $expense
            ? $this->user()->can('update', $expense)
            : $this->user()->can('create', Expense::class);
    }

    public function rules(): array
    {
        /** @var Expense|null $expense */
        $expense = $this->route('expense');
        $required = $expense ? 'sometimes' : 'required';
        $category = ExpenseCategory::tryFrom((string) $this->input('category', $expense?->category?->value));

        return [
            'category' => [$required, Rule::enum(ExpenseCategory::class)],
            'label' => [$required, 'string', 'max:150'],
            'amount' => [$required, 'integer', 'min:1', 'max:1000000000'],
            'expense_date' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
            'period_month' => [
                Rule::requiredIf(fn () => $category?->isMonthly() && ($expense === null || $this->has('period_month'))),
                'nullable',
                'date_format:Y-m',
            ],
            'due_date' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
            'paid_at' => ['sometimes', 'nullable', 'date_format:Y-m-d', 'before_or_equal:today'],
        ];
    }
}
