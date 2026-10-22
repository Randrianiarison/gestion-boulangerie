<?php

namespace App\Models;

use App\Casts\DateOnly;
use App\Enums\SaleSource;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Sale extends Model
{
    protected $fillable = [
        'product_id',
        'sold_on',
        'quantity',
        'unit_price',
        'total',
        'source',
        'day_closing_id',
        'user_id',
    ];

    protected function casts(): array
    {
        return [
            'sold_on' => DateOnly::class,
            'quantity' => 'integer',
            'unit_price' => 'integer',
            'total' => 'integer',
            'source' => SaleSource::class,
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

    public function dayClosing(): BelongsTo
    {
        return $this->belongsTo(DayClosing::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
