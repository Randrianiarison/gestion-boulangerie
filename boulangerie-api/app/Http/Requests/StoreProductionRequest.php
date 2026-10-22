<?php

namespace App\Http\Requests;

use App\Http\Requests\Concerns\ResolvesDates;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreProductionRequest extends FormRequest
{
    use ResolvesDates;

    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'produced_on' => ['nullable', 'date_format:Y-m-d', 'before_or_equal:today'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.product_id' => ['required', 'integer', 'distinct', Rule::exists('products', 'id')->where('active', true)],
            'items.*.quantity' => ['required', 'integer', 'min:1', 'max:100000'],
        ];
    }
}
