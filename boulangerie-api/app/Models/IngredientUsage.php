<?php

namespace App\Models;

use App\Casts\DateOnly;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class IngredientUsage extends Model
{
    protected $fillable = [
        'ingredient_id',
        'used_on',
        'quantity',
        'note',
        'user_id',
    ];

    protected function casts(): array
    {
        return [
            'used_on' => DateOnly::class,
            'quantity' => 'float',
        ];
    }

    public function ingredient(): BelongsTo
    {
        return $this->belongsTo(Ingredient::class);
    }
}
