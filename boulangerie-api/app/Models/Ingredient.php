<?php

namespace App\Models;

use App\Enums\IngredientUnit;
use Database\Factories\IngredientFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Ingredient extends Model
{
    /** @use HasFactory<IngredientFactory> */
    use HasFactory;

    protected $fillable = [
        'name_fr',
        'name_mg',
        'unit',
        'alert_threshold',
        'active',
    ];

    protected function casts(): array
    {
        return [
            'unit' => IngredientUnit::class,
            'alert_threshold' => 'float',
            'active' => 'boolean',
        ];
    }

    public function purchases(): HasMany
    {
        return $this->hasMany(IngredientPurchase::class);
    }

    public function usages(): HasMany
    {
        return $this->hasMany(IngredientUsage::class);
    }

    /** Ajoute purchases_sum_quantity et usages_sum_quantity pour calculer le stock sans requête par ligne. */
    public function scopeWithStock(Builder $query): void
    {
        $query->withSum('purchases', 'quantity')->withSum('usages', 'quantity');
    }

    /** Stock = achats - utilisations. */
    public function stock(): float
    {
        $purchased = $this->purchases_sum_quantity ?? $this->purchases()->sum('quantity');
        $used = $this->usages_sum_quantity ?? $this->usages()->sum('quantity');

        return round((float) $purchased - (float) $used, 3);
    }

    public function isBelowThreshold(): bool
    {
        return $this->stock() < $this->alert_threshold;
    }

    public function displayName(): string
    {
        return app()->getLocale() === 'mg' ? $this->name_mg : $this->name_fr;
    }
}
