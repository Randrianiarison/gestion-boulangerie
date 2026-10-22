<?php

namespace App\Http\Requests;

use App\Enums\IngredientUnit;
use App\Models\Ingredient;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/** Création (POST) et modification (PUT/PATCH) d'un ingrédient. */
class IngredientRequest extends FormRequest
{
    public function authorize(): bool
    {
        $ingredient = $this->route('ingredient');

        return $ingredient
            ? $this->user()->can('update', $ingredient)
            : $this->user()->can('create', Ingredient::class);
    }

    public function rules(): array
    {
        $required = $this->route('ingredient') ? 'sometimes' : 'required';

        return [
            'name_fr' => [$required, 'string', 'max:100'],
            'name_mg' => [$required, 'string', 'max:100'],
            'unit' => [$required, Rule::enum(IngredientUnit::class)],
            'alert_threshold' => [$required, 'numeric', 'min:0', 'max:1000000'],
            'active' => ['sometimes', 'boolean'],
        ];
    }
}
