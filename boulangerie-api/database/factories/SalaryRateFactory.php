<?php

namespace Database\Factories;

use App\Models\Employee;
use App\Models\SalaryRate;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<SalaryRate>
 */
class SalaryRateFactory extends Factory
{
    public function definition(): array
    {
        return [
            'employee_id' => Employee::factory(),
            'monthly_amount' => 150000,
            'effective_from' => '2026-01-01',
        ];
    }
}
