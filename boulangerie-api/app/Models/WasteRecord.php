<?php

namespace App\Models;

use App\Casts\DateOnly;
use App\Enums\WasteReason;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WasteRecord extends Model
{
    protected $fillable = [
        'product_id',
        'stock_lot_id',
        'date',
        'quantity',
        'reason',
        'unit_price',
        'recovered_amount',
        'note',
        'day_closing_id',
        'user_id',
    ];

    protected function casts(): array
    {
        return [
            'date' => DateOnly::class,
            'quantity' => 'integer',
            'reason' => WasteReason::class,
            'unit_price' => 'integer',
            'recovered_amount' => 'integer',
        ];
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function stockLot(): BelongsTo
    {
        return $this->belongsTo(StockLot::class);
    }

    public function dayClosing(): BelongsTo
    {
        return $this->belongsTo(DayClosing::class);
    }

    /** Chiffre d'affaires perdu, au prix de vente (informatif). */
    public function lostValue(): int
    {
        return $this->quantity * $this->unit_price;
    }
}
