<?php

namespace Database\Factories;

use App\Enums\ExpenseCategory;
use App\Models\Expense;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Expense>
 */
class ExpenseFactory extends Factory
{
    public function definition(): array
    {
        return [
            'category' => ExpenseCategory::Transport,
            'label' => fake()->words(2, true),
            'amount' => 10000,
            'expense_date' => '2026-10-01',
            'period_month' => null,
            'due_date' => null,
            'paid_at' => null,
        ];
    }

    /** Facture mensuelle (électricité par défaut), répartie au prorata des jours du mois. */
    public function monthly(string $periodMonth, int $amount, ExpenseCategory $category = ExpenseCategory::Electricity): static
    {
        return $this->state(fn () => [
            'category' => $category,
            'label' => $category === ExpenseCategory::Electricity ? 'JIRAMA '.$periodMonth : 'Loyer '.$periodMonth,
            'amount' => $amount,
            'expense_date' => $periodMonth.'-01',
            'period_month' => $periodMonth,
        ]);
    }
}
