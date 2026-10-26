<?php

namespace Database\Factories;

use App\Enums\ProductCategory;
use App\Enums\ProductFormat;
use App\Models\Product;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Product>
 */
class ProductFactory extends Factory
{
    public function definition(): array
    {
        $name = fake()->unique()->word();

        return [
            'category' => ProductCategory::Bread,
            'name_fr' => 'Pain '.$name,
            'name_mg' => 'Mofo '.$name,
            'format' => ProductFormat::Piece,
            'unit_price' => 500,
            'shelf_life_days' => 1,
            'active' => true,
        ];
    }

    /** Se conserve plusieurs jours. */
    public function keeps(int $days): static
    {
        return $this->state(fn () => ['shelf_life_days' => $days]);
    }

    /** Jus en bouteille (1 L par défaut). */
    public function juice(int $volumeMl = 1000): static
    {
        return $this->state(fn () => [
            'category' => ProductCategory::Juice,
            'name_fr' => 'Jus '.fake()->unique()->word(),
            'name_mg' => 'Ranom-boankazo '.fake()->unique()->word(),
            'format' => ProductFormat::Bottle,
            'volume_ml' => $volumeMl,
            'unit_price' => 3000,
        ]);
    }

    /** Ancien jus vendu au verre (plus proposé, désactivé). */
    public function glass(): static
    {
        return $this->juice()->state(fn () => [
            'format' => ProductFormat::Glass,
            'unit_price' => 1000,
            'active' => false,
        ]);
    }
}
