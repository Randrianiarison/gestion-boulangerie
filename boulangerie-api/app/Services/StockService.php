<?php

namespace App\Services;

use App\Exceptions\BusinessRuleException;
use App\Models\Product;
use App\Models\StockLot;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Support\Collection;

class StockService
{
    /**
     * Stock par produit à une date.
     *
     * - available : lots vendables ce jour (dont ceux qui expirent ce jour) ;
     * - expiring  : part de available qui expire ce jour (invendu si elle n'est pas vendue) ;
     * - stale     : restes de lots déjà expirés dont la clôture a été oubliée.
     *
     * @return Collection<int, array{product: Product, available: int, expiring: int, stale: int}>
     */
    public function availabilityOn(CarbonImmutable $date, bool $includeEmptyActive = false): Collection
    {
        $lots = StockLot::query()
            ->where('produced_on', '<=', $date->toDateString())
            ->where('quantity_remaining', '>', 0)
            ->get()
            ->groupBy('product_id');

        $products = Product::query()
            ->where(function ($query) use ($lots, $includeEmptyActive) {
                $query->whereIn('id', $lots->keys());
                if ($includeEmptyActive) {
                    $query->orWhere('active', true);
                }
            })
            ->orderBy('category')
            ->orderBy('name_fr')
            ->orderByDesc('format')
            ->get();

        return $products->map(function (Product $product) use ($lots, $date) {
            /** @var Collection<int, StockLot> $productLots */
            $productLots = $lots->get($product->id, collect());

            return [
                'product' => $product,
                'available' => (int) $productLots->filter(fn (StockLot $lot) => $lot->expires_on->gte($date))->sum('quantity_remaining'),
                'expiring' => (int) $productLots->filter(fn (StockLot $lot) => $lot->expires_on->eq($date))->sum('quantity_remaining'),
                'stale' => (int) $productLots->filter(fn (StockLot $lot) => $lot->expires_on->lt($date))->sum('quantity_remaining'),
            ];
        })->values();
    }

    public function available(Product $product, CarbonImmutable $date): int
    {
        return (int) StockLot::query()
            ->where('product_id', $product->id)
            ->availableOn($date)
            ->sum('quantity_remaining');
    }

    public function produce(Product $product, int $quantity, CarbonImmutable $date, ?User $user = null): StockLot
    {
        return StockLot::create([
            'product_id' => $product->id,
            'produced_on' => $date,
            'expires_on' => $product->expiryDateFor($date),
            'quantity_produced' => $quantity,
            'quantity_remaining' => $quantity,
            'user_id' => $user?->id,
        ]);
    }

    /**
     * Retire une quantité des lots vendables, le plus ancien d'abord (FIFO).
     * À appeler dans une transaction.
     *
     * @return list<array{lot: StockLot, quantity: int}>
     *
     * @throws BusinessRuleException insufficient_stock
     */
    public function take(Product $product, int $quantity, CarbonImmutable $date): array
    {
        $lots = StockLot::query()
            ->where('product_id', $product->id)
            ->availableOn($date)
            ->fifo()
            ->lockForUpdate()
            ->get();

        $available = (int) $lots->sum('quantity_remaining');
        if ($available < $quantity) {
            throw new BusinessRuleException('insufficient_stock', [
                'product' => $product->displayName(),
                'available' => $available,
                'requested' => $quantity,
            ]);
        }

        $taken = [];
        $left = $quantity;
        foreach ($lots as $lot) {
            if ($left === 0) {
                break;
            }
            $part = min($left, $lot->quantity_remaining);
            $lot->decrement('quantity_remaining', $part);
            $taken[] = ['lot' => $lot, 'quantity' => $part];
            $left -= $part;
        }

        return $taken;
    }

    /** Remet une quantité dans un lot (annulation d'une clôture). */
    public function giveBack(int $stockLotId, int $quantity): void
    {
        StockLot::whereKey($stockLotId)->increment('quantity_remaining', $quantity);
    }
}
