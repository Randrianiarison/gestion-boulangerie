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
        'volume_ml',
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
            'volume_ml' => 'integer',
            'unit_price' => 'integer',
            'shelf_life_days' => 'integer',
            'active' => 'boolean',
        ];
    }

    protected static function booted(): void
    {
        // Seule une bouteille a une contenance.
        static::saving(function (Product $product) {
            if ($product->format !== ProductFormat::Bottle) {
                $product->volume_ml = null;
            }
        });
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

    /** Ordre des listes : pains puis jus, par nom, pièce/verre/bouteille, petit/moyen/grand, puis 50 cl avant 1 L. */
    public function scopeCatalogOrder(Builder $query): void
    {
        $query->orderBy('category')
            ->orderBy('name_fr')
            ->orderByDesc('format')
            ->orderByRaw("case size when 'small' then 1 when 'medium' then 2 when 'large' then 3 else 0 end")
            ->orderBy('volume_ml');
    }

    /** Un pain à 1 jour expire le jour même ; à 3 jours, le surlendemain. */
    public function expiryDateFor(CarbonImmutable $producedOn): CarbonImmutable
    {
        return $producedOn->addDays(max(1, $this->shelf_life_days) - 1);
    }

    /** Nom dans la langue courante, avec contenance, format ou taille : « Jus d'orange (1 L) », « Pain au chocolat (grand) ». */
    public function displayName(): string
    {
        $name = app()->getLocale() === 'mg' ? $this->name_mg : $this->name_fr;

        $details = array_filter([
            match (true) {
                $this->volume_ml !== null => self::volumeLabel($this->volume_ml),
                $this->format === ProductFormat::Piece => null,
                default => __('messages.formats.'.$this->format->value),
            },
            $this->size === null ? null : __('messages.sizes.'.$this->size->value),
        ]);

        return $details === [] ? $name : $name.' ('.implode(', ', $details).')';
    }

    /** 330 → « 33 cl », 1000 → « 1 L », 1500 → « 1,5 L », 125 → « 125 ml ». */
    public static function volumeLabel(int $milliliters): string
    {
        if ($milliliters >= 1000) {
            return str_replace('.', ',', (string) ($milliliters / 1000)).' L';
        }

        return $milliliters % 10 === 0 ? intdiv($milliliters, 10).' cl' : $milliliters.' ml';
    }
}
