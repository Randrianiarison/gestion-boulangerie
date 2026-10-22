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

    public function juice(ProductFormat $format = ProductFormat::Glass): static
    {
        return $this->state(fn () => [
            'category' => ProductCategory::Juice,
            'name_fr' => 'Jus '.fake()->unique()->word(),
            'name_mg' => 'Ranom-boankazo '.fake()->unique()->word(),
            'format' => $format,
            'unit_price' => $format === ProductFormat::Bottle ? 3000 : 1000,
        ]);
    }
}
