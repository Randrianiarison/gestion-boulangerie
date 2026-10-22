<?php

namespace App\Models;

use App\Casts\DateOnly;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class IngredientPurchase extends Model
{
    protected $fillable = [
        'ingredient_id',
        'purchased_on',
        'quantity',
        'unit_price',
        'total',
        'supplier',
        'user_id',
    ];

    protected function casts(): array
    {
        return [
            'purchased_on' => DateOnly::class,
            'quantity' => 'float',
            'unit_price' => 'integer',
            'total' => 'integer',
        ];
    }

    public function ingredient(): BelongsTo
    {
        return $this->belongsTo(Ingredient::class);
    }
}
