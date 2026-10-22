<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreSalaryRateRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('update', $this->route('employee'));
    }

    public function rules(): array
    {
        return [
            'monthly_amount' => ['required', 'integer', 'min:0', 'max:100000000'],
            'effective_from' => ['required', 'date_format:Y-m-d'],
        ];
    }
}
