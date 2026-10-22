<?php

namespace App\Services;

use App\Enums\WasteReason;
use App\Models\Product;
use App\Models\User;
use App\Models\WasteRecord;
use Carbon\CarbonImmutable;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class WasteService
{
    public function __construct(
        private readonly StockService $stock,
        private readonly DayLock $lock,
    ) {}

    /**
     * Invendu saisi à la main (abîmé, autre), retiré des lots en FIFO.
     * Les invendus « expirés » sont créés par la clôture.
     *
     * @return Collection<int, WasteRecord>
     */
    public function record(
        Product $product,
        int $quantity,
        CarbonImmutable $date,
        WasteReason $reason,
        int $recoveredAmount,
        ?string $note,
        ?User $user,
    ): Collection {
        return DB::transaction(function () use ($product, $quantity, $date, $reason, $recoveredAmount, $note, $user) {
            $this->lock->assertOpen($date);

            return collect($this->stock->take($product, $quantity, $date))
                ->values()
                ->map(fn (array $part, int $index) => WasteRecord::create([
                    'product_id' => $product->id,
                    'stock_lot_id' => $part['lot']->id,
                    'date' => $date,
                    'quantity' => $part['quantity'],
                    'reason' => $reason,
                    'unit_price' => $product->unit_price,
                    'recovered_amount' => $index === 0 ? $recoveredAmount : 0,
                    'note' => $note,
                    'user_id' => $user?->id,
                ]));
        });
    }
}
