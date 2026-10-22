<?php

namespace App\Http\Requests;

use App\Http\Requests\Concerns\ResolvesDates;
use App\Models\Ingredient;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreIngredientUsageRequest extends FormRequest
{
    use ResolvesDates;

    public function authorize(): bool
    {
        return $this->user()->can('recordMovement', Ingredient::class);
    }

    public function rules(): array
    {
        return [
            'ingredient_id' => ['required', 'integer', Rule::exists('ingredients', 'id')],
            'used_on' => ['nullable', 'date_format:Y-m-d', 'before_or_equal:today'],
            'quantity' => ['required', 'numeric', 'gt:0', 'max:1000000'],
            'note' => ['nullable', 'string', 'max:255'],
        ];
    }
}
