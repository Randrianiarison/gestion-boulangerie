<?php

namespace App\Http\Requests;

use App\Http\Requests\Concerns\ResolvesDates;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreSaleRequest extends FormRequest
{
    use ResolvesDates;

    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'sold_on' => ['nullable', 'date_format:Y-m-d', 'before_or_equal:today'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.product_id' => ['required', 'integer', Rule::exists('products', 'id')],
            'items.*.quantity' => ['required', 'integer', 'min:1', 'max:100000'],
        ];
    }
}
