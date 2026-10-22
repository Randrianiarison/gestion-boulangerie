<?php

namespace App\Models;

use App\Enums\ProductCategory;
use App\Enums\ProductFormat;
use Carbon\CarbonImmutable;
use Database\Factories\ProductFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Product extends Model
{
    /** @use HasFactory<ProductFactory> */
    use HasFactory;

    protected $fillable = [
        'category',
        'name_fr',
        'name_mg',
        'format',
        'unit_price',
        'shelf_life_days',
        'active',
    ];

    protected function casts(): array
    {
        return [
            'category' => ProductCategory::class,
            'format' => ProductFormat::class,
            'unit_price' => 'integer',
            'shelf_life_days' => 'integer',
            'active' => 'boolean',
        ];
    }

    public function stockLots(): HasMany
    {
        return $this->hasMany(StockLot::class);
    }

    public function sales(): HasMany
    {
        return $this->hasMany(Sale::class);
    }

    public function wasteRecords(): HasMany
    {
        return $this->hasMany(WasteRecord::class);
    }

    public function scopeActive(Builder $query): void
    {
        $query->where('active', true);
    }

    /** Un pain à 1 jour expire le jour même ; à 3 jours, le surlendemain. */
    public function expiryDateFor(CarbonImmutable $producedOn): CarbonImmutable
    {
        return $producedOn->addDays(max(1, $this->shelf_life_days) - 1);
    }

    /** Nom dans la langue courante, avec le format pour les jus : « Jus de papaye (verre) ». */
    public function displayName(): string
    {
        $name = app()->getLocale() === 'mg' ? $this->name_mg : $this->name_fr;

        if ($this->format === ProductFormat::Piece) {
            return $name;
        }

        return $name.' ('.__('messages.formats.'.$this->format->value).')';
    }
}
