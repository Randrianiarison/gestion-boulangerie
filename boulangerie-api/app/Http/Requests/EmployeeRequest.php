<?php

namespace App\Http\Requests;

use App\Enums\EmployeeRole;
use App\Models\Employee;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/** Création (avec le salaire de départ) et modification d'un employé. */
class EmployeeRequest extends FormRequest
{
    public function authorize(): bool
    {
        $employee = $this->route('employee');

        return $employee
            ? $this->user()->can('update', $employee)
            : $this->user()->can('create', Employee::class);
    }

    public function rules(): array
    {
        /** @var Employee|null $employee */
        $employee = $this->route('employee');
        $required = $employee ? 'sometimes' : 'required';
        $hiredOn = $this->input('hired_on', $employee?->hired_on?->toDateString());

        return [
            'name' => [$required, 'string', 'max:100'],
            'phone' => ['sometimes', 'nullable', 'string', 'max:20'],
            'role' => [$required, Rule::enum(EmployeeRole::class)],
            'hired_on' => [$required, 'date_format:Y-m-d'],
            'left_on' => array_filter(['sometimes', 'nullable', 'date_format:Y-m-d', $hiredOn ? 'after_or_equal:'.$hiredOn : null]),
            'monthly_amount' => $employee ? ['prohibited'] : ['required', 'integer', 'min:0', 'max:100000000'],
        ];
    }
}
