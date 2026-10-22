<?php

namespace Database\Factories;

use App\Enums\IngredientUnit;
use App\Models\Ingredient;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Ingredient>
 */
class IngredientFactory extends Factory
{
    public function definition(): array
    {
        $name = fake()->unique()->word();

        return [
            'name_fr' => ucfirst($name),
            'name_mg' => ucfirst($name),
            'unit' => IngredientUnit::Kg,
            'alert_threshold' => 5,
            'active' => true,
        ];
    }
}
