<?php

namespace Database\Factories;

use App\Enums\EmployeeRole;
use App\Models\Employee;
use App\Models\SalaryRate;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Employee>
 */
class EmployeeFactory extends Factory
{
    public function definition(): array
    {
        return [
            'name' => fake()->firstName(),
            'phone' => '03'.fake()->numerify('########'),
            'role' => EmployeeRole::Preparation,
            'hired_on' => '2026-01-01',
            'left_on' => null,
        ];
    }

    /** Salaire mensuel en vigueur dès l'embauche. */
    public function withSalary(int $monthlyAmount): static
    {
        return $this->afterCreating(function (Employee $employee) use ($monthlyAmount) {
            SalaryRate::create([
                'employee_id' => $employee->id,
                'monthly_amount' => $monthlyAmount,
                'effective_from' => $employee->hired_on,
            ]);
        });
    }
}
