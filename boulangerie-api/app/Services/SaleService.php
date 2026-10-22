<?php

namespace App\Services;

use App\Enums\SaleSource;
use App\Models\DayClosing;
use App\Models\Product;
use App\Models\Sale;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class SaleService
{
    public function __construct(
        private readonly StockService $stock,
        private readonly DayLock $lock,
    ) {}

    /**
     * Ventes directes au comptoir ; tout ou rien si un produit manque.
     *
     * @param  array<int, array{product_id: int, quantity: int}>  $items
     * @return Collection<int, Sale>
     */
    public function recordCounterSales(CarbonImmutable $date, array $items, ?User $user): Collection
    {
        return DB::transaction(function () use ($date, $items, $user) {
            $this->lock->assertOpen($date);

            // Un même produit saisi deux fois devient une seule vente.
            $quantities = collect($items)->groupBy('product_id')->map(fn (Collection $lines) => (int) $lines->sum('quantity'));
            $products = Product::findMany($quantities->keys())->keyBy('id');

            return $quantities
                ->map(fn (int $quantity, int $productId) => $this->sell($products[$productId], $quantity, $date, SaleSource::Counter, $user))
                ->values();
        });
    }

    /** Enregistre une vente au prix du jour en consommant les lots en FIFO. */
    public function sell(
        Product $product,
        int $quantity,
        CarbonImmutable $date,
        SaleSource $source,
        ?User $user,
        ?DayClosing $closing = null,
    ): Sale {
        $taken = $this->stock->take($product, $quantity, $date);

        $sale = Sale::create([
            'product_id' => $product->id,
            'sold_on' => $date,
            'quantity' => $quantity,
            'unit_price' => $product->unit_price,
            'total' => $quantity * $product->unit_price,
            'source' => $source,
            'day_closing_id' => $closing?->id,
            'user_id' => $user?->id,
        ]);

        foreach ($taken as $part) {
            $sale->allocations()->create(['stock_lot_id' => $part['lot']->id, 'quantity' => $part['quantity']]);
        }

        return $sale->setRelation('product', $product);
    }
}
