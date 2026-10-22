<?php

namespace App\Http\Requests;

use App\Http\Requests\Concerns\ResolvesDates;
use App\Models\Ingredient;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreIngredientPurchaseRequest extends FormRequest
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
            'purchased_on' => ['nullable', 'date_format:Y-m-d', 'before_or_equal:today'],
            'quantity' => ['required', 'numeric', 'gt:0', 'max:1000000'],
            // Prix unitaire OU total payé : l'autre est calculé.
            'unit_price' => ['nullable', 'required_without:total', 'integer', 'min:0', 'max:100000000'],
            'total' => ['nullable', 'required_without:unit_price', 'integer', 'min:0', 'max:1000000000'],
            'supplier' => ['nullable', 'string', 'max:100'],
        ];
    }
}
