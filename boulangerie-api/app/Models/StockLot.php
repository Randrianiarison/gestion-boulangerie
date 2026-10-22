<?php

namespace App\Models;

use App\Casts\DateOnly;
use Carbon\CarbonInterface;
use Database\Factories\StockLotFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class StockLot extends Model
{
    /** @use HasFactory<StockLotFactory> */
    use HasFactory;

    protected $fillable = [
        'product_id',
        'produced_on',
        'expires_on',
        'quantity_produced',
        'quantity_remaining',
        'user_id',
    ];

    protected function casts(): array
    {
        return [
            'produced_on' => DateOnly::class,
            'expires_on' => DateOnly::class,
            'quantity_produced' => 'integer',
            'quantity_remaining' => 'integer',
        ];
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function allocations(): HasMany
    {
        return $this->hasMany(SaleAllocation::class);
    }

    public function wasteRecords(): HasMany
    {
        return $this->hasMany(WasteRecord::class);
    }

    /** Lots vendables ce jour-là : déjà produits, pas encore expirés, non vides. */
    public function scopeAvailableOn(Builder $query, CarbonInterface $date): void
    {
        $query->where('produced_on', '<=', $date->toDateString())
            ->where('expires_on', '>=', $date->toDateString())
            ->where('quantity_remaining', '>', 0);
    }

    /** Lots arrivés à expiration à cette date (ou avant, si une clôture a été oubliée). */
    public function scopeExpiredBy(Builder $query, CarbonInterface $date): void
    {
        $query->where('expires_on', '<=', $date->toDateString())
            ->where('quantity_remaining', '>', 0);
    }

    /** Ordre FIFO : le lot qui expire le premier, puis le plus ancien. */
    public function scopeFifo(Builder $query): void
    {
        $query->orderBy('expires_on')->orderBy('produced_on')->orderBy('id');
    }
}
