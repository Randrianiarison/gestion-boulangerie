<?php

namespace App\Models;

use App\Enums\ProductCategory;
use App\Enums\ProductFormat;
use App\Enums\ProductSize;
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
        'size',
        'unit_price',
        'shelf_life_days',
        'active',
    ];

    protected function casts(): array
    {
        return [
            'category' => ProductCategory::class,
            'format' => ProductFormat::class,
            'size' => ProductSize::class,
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

    /** Ordre des listes : pains puis jus, par nom, pièce/verre/bouteille, puis petit/moyen/grand. */
    public function scopeCatalogOrder(Builder $query): void
    {
        $query->orderBy('category')
            ->orderBy('name_fr')
            ->orderByDesc('format')
            ->orderByRaw("case size when 'small' then 1 when 'medium' then 2 when 'large' then 3 else 0 end");
    }

    /** Un pain à 1 jour expire le jour même ; à 3 jours, le surlendemain. */
    public function expiryDateFor(CarbonImmutable $producedOn): CarbonImmutable
    {
        return $producedOn->addDays(max(1, $this->shelf_life_days) - 1);
    }

    /** Nom dans la langue courante, avec format et taille : « Jus de papaye (verre) », « Pain au chocolat (grand) ». */
    public function displayName(): string
    {
        $name = app()->getLocale() === 'mg' ? $this->name_mg : $this->name_fr;

        $details = array_filter([
            $this->format === ProductFormat::Piece ? null : __('messages.formats.'.$this->format->value),
            $this->size === null ? null : __('messages.sizes.'.$this->size->value),
        ]);

        return $details === [] ? $name : $name.' ('.implode(', ', $details).')';
    }
}
