<?php

namespace App\Http\Requests;

use App\Http\Requests\Concerns\ResolvesDates;
use Illuminate\Foundation\Http\FormRequest;

class PayExpenseRequest extends FormRequest
{
    use ResolvesDates;

    public function authorize(): bool
    {
        return $this->user()->can('update', $this->route('expense'));
    }

    public function rules(): array
    {
        return [
            'paid_at' => ['nullable', 'date_format:Y-m-d', 'before_or_equal:today'],
        ];
    }
}
