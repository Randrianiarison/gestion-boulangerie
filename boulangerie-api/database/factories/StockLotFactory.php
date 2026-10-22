<?php

namespace Database\Factories;

use App\Models\Product;
use App\Models\StockLot;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<StockLot>
 */
class StockLotFactory extends Factory
{
    public function definition(): array
    {
        return [
            'product_id' => Product::factory(),
            'produced_on' => CarbonImmutable::today(),
            'quantity_produced' => 20,
            'quantity_remaining' => 20,
        ];
    }

    public function configure(): static
    {
        // expires_on suit la durée de conservation du produit si elle n'est pas fournie.
        return $this->afterMaking(function (StockLot $lot) {
            $lot->expires_on ??= $lot->product->expiryDateFor($lot->produced_on);
        });
    }

    public function producedOn(string $date, int $quantity): static
    {
        return $this->state(fn () => [
            'produced_on' => $date,
            'quantity_produced' => $quantity,
            'quantity_remaining' => $quantity,
        ]);
    }
}
