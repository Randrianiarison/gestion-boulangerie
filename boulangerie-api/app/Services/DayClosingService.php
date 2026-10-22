<?php

namespace App\Services;

use App\Enums\ClosingMode;
use App\Enums\SaleSource;
use App\Enums\WasteReason;
use App\Exceptions\BusinessRuleException;
use App\Models\DayClosing;
use App\Models\Product;
use App\Models\Sale;
use App\Models\StockLot;
use App\Models\User;
use App\Models\WasteRecord;
use Carbon\CarbonImmutable;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/**
 * Clôture de journée : vendu = disponible - restant compté, puis les lots
 * arrivés à expiration passent en invendus. Les autres lots sont reportés.
 */
class DayClosingService
{
    public function __construct(
        private readonly StockService $stock,
        private readonly SaleService $sales,
        private readonly DayLock $lock,
    ) {}

    public function find(CarbonImmutable $date): ?DayClosing
    {
        return DayClosing::where('date', $date->toDateString())->first();
    }

    /**
     * Clôture saisie à l'écran.
     *
     * @param  array<int, array{product_id: int, remaining: int, recovered_amount?: int|null}>  $counts
     */
    public function close(CarbonImmutable $date, array $counts, ?User $user): DayClosing
    {
        return DB::transaction(
            fn () => $this->run($date, collect($counts)->keyBy('product_id'), $user, ClosingMode::Counted)
        );
    }

    /**
     * Clôture de rattrapage sans comptage (commande artisan) : rien n'est réputé vendu,
     * les lots expirés passent en invendus. Idempotente : null si la journée est déjà clôturée.
     */
    public function closeAutomatically(CarbonImmutable $date): ?DayClosing
    {
        if ($this->find($date) !== null) {
            return null;
        }

        return DB::transaction(fn () => $this->run($date, null, null, ClosingMode::Automatic));
    }

    /** Code d'erreur empêchant l'annulation, ou null si elle est possible. */
    public function cancelBlockedReason(DayClosing $closing): ?string
    {
        $date = $closing->date->toDateString();

        if (DayClosing::where('date', '>', $date)->exists()) {
            return 'closing_not_latest';
        }

        if (Sale::where('sold_on', '>', $date)->exists() || WasteRecord::where('date', '>', $date)->exists()) {
            return 'closing_has_later_operations';
        }

        return null;
    }

    /** Annule une clôture : ventes et invendus supprimés, quantités remises dans leurs lots. */
    public function cancel(CarbonImmutable $date): void
    {
        DB::transaction(function () use ($date) {
            $closing = DayClosing::where('date', $date->toDateString())->lockForUpdate()->first();
            if ($closing === null) {
                throw new BusinessRuleException('closing_not_found', ['date' => $date->toDateString()], 404);
            }

            $reason = $this->cancelBlockedReason($closing);
            if ($reason !== null) {
                throw new BusinessRuleException($reason, ['date' => $date->toDateString()]);
            }

            foreach ($closing->sales()->with('allocations')->get() as $sale) {
                foreach ($sale->allocations as $allocation) {
                    $this->stock->giveBack($allocation->stock_lot_id, $allocation->quantity);
                }
                $sale->delete();
            }

            foreach ($closing->wasteRecords as $record) {
                $this->stock->giveBack($record->stock_lot_id, $record->quantity);
                $record->delete();
            }

            $closing->delete();
        });
    }

    /**
     * @param  Collection<int, array{product_id: int, remaining: int, recovered_amount?: int|null}>|null  $counts
     */
    private function run(CarbonImmutable $date, ?Collection $counts, ?User $user, ClosingMode $mode): DayClosing
    {
        $this->lock->assertOpen($date);

        $availability = $this->stock->availabilityOn($date)->keyBy(fn (array $row) => $row['product']->id);
        if ($counts !== null) {
            $this->validateCounts($availability, $counts);
        }

        $closing = DayClosing::create(['date' => $date, 'mode' => $mode, 'user_id' => $user?->id]);

        foreach ($availability as $productId => $row) {
            $remaining = $counts?->get($productId)['remaining'] ?? $row['available'];
            $sold = $row['available'] - $remaining;
            if ($sold > 0) {
                $this->sales->sell($row['product'], $sold, $date, SaleSource::Closing, $user, $closing);
            }
        }

        $waste = $this->expireLots($date, $closing, $user);

        if ($counts !== null) {
            $this->applyRecoveredAmounts($counts, $waste);
        }

        return $closing;
    }

    /**
     * @param  Collection<int, array{product: Product, available: int, expiring: int, stale: int}>  $availability
     * @param  Collection<int, array{product_id: int, remaining: int, recovered_amount?: int|null}>  $counts
     */
    private function validateCounts(Collection $availability, Collection $counts): void
    {
        $missing = $availability->filter(fn (array $row, int $productId) => $row['available'] > 0 && ! $counts->has($productId));
        if ($missing->isNotEmpty()) {
            throw new BusinessRuleException('closing_missing_products', [
                'products' => $missing->map(fn (array $row) => $row['product']->displayName())->implode(', '),
            ]);
        }

        foreach ($counts as $productId => $count) {
            $available = $availability->get($productId)['available'] ?? 0;
            if ($count['remaining'] > $available) {
                $product = $availability->get($productId)['product'] ?? Product::findOrFail($productId);

                throw new BusinessRuleException('remaining_exceeds_available', [
                    'product' => $product->displayName(),
                    'remaining' => $count['remaining'],
                    'available' => $available,
                ]);
            }
        }
    }

    /** @return Collection<int, WasteRecord> */
    private function expireLots(CarbonImmutable $date, DayClosing $closing, ?User $user): Collection
    {
        $lots = StockLot::query()->expiredBy($date)->with('product')->fifo()->lockForUpdate()->get();

        return $lots->map(function (StockLot $lot) use ($date, $closing, $user) {
            $record = WasteRecord::create([
                'product_id' => $lot->product_id,
                'stock_lot_id' => $lot->id,
                'date' => $date,
                'quantity' => $lot->quantity_remaining,
                'reason' => WasteReason::Expired,
                'unit_price' => $lot->product->unit_price,
                'day_closing_id' => $closing->id,
                'user_id' => $user?->id,
            ]);
            $lot->update(['quantity_remaining' => 0]);

            return $record;
        });
    }

    /**
     * Montant récupéré saisi par produit, porté sur son premier invendu.
     *
     * @param  Collection<int, array{product_id: int, remaining: int, recovered_amount?: int|null}>  $counts
     * @param  Collection<int, WasteRecord>  $waste
     */
    private function applyRecoveredAmounts(Collection $counts, Collection $waste): void
    {
        foreach ($counts as $productId => $count) {
            $amount = (int) ($count['recovered_amount'] ?? 0);
            if ($amount === 0) {
                continue;
            }

            $record = $waste->firstWhere('product_id', $productId);
            if ($record === null) {
                throw new BusinessRuleException('recovered_without_waste', [
                    'product' => Product::findOrFail($productId)->displayName(),
                ]);
            }

            $record->update(['recovered_amount' => $amount]);
        }
    }
}
