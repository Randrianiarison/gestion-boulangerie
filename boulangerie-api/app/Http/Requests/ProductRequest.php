<?php

namespace App\Http\Requests;

use App\Enums\ProductCategory;
use App\Enums\ProductFormat;
use App\Enums\ProductSize;
use App\Models\Product;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/** Création (POST) et modification (PUT/PATCH) d'un produit. */
class ProductRequest extends FormRequest
{
    public function authorize(): bool
    {
        $product = $this->route('product');

        return $product
            ? $this->user()->can('update', $product)
            : $this->user()->can('create', Product::class);
    }

    public function rules(): array
    {
        /** @var Product|null $product */
        $product = $this->route('product');
        $required = $product ? 'sometimes' : 'required';
        $category = $this->input('category', $product?->category?->value);
        $format = $this->input('format', $product?->format?->value);
        $size = $this->exists('size') ? $this->input('size') : $product?->size?->value;
        $volume = $this->exists('volume_ml') ? $this->input('volume_ml') : $product?->volume_ml;
        $isBottle = $format === ProductFormat::Bottle->value;

        return [
            'category' => [$required, Rule::enum(ProductCategory::class)],
            'name_fr' => [$required, 'string', 'max:100'],
            'name_mg' => [$required, 'string', 'max:100'],
            // Un seul « Pain au chocolat » par taille, un seul « Jus d'orange » par contenance
            // (sans taille ou sans contenance compte comme une valeur).
            'format' => [
                $required,
                Rule::in($this->allowedFormats($category, $product)),
                Rule::unique('products')
                    ->where('name_fr', $this->input('name_fr', $product?->name_fr))
                    ->where(fn ($query) => $size === null ? $query->whereNull('size') : $query->where('size', $size))
                    ->where(fn ($query) => $isBottle && $volume !== null ? $query->where('volume_ml', $volume) : $query->whereNull('volume_ml'))
                    ->ignore($product),
            ],
            'size' => ['sometimes', 'nullable', Rule::enum(ProductSize::class)],
            // Contenance en millilitres : obligatoire pour une bouteille (une ancienne bouteille sans
            // contenance doit la recevoir dès qu'on la modifie), sans objet pour le reste.
            'volume_ml' => [
                Rule::requiredIf($isBottle && $volume === null && ($product === null || $this->hasAny(['format', 'volume_ml']))),
                Rule::prohibitedIf(! $isBottle),
                'nullable',
                'integer',
                'min:50',
                'max:10000',
            ],
            'unit_price' => [$required, 'integer', 'min:0', 'max:10000000'],
            'shelf_life_days' => [$required, 'integer', 'min:1', 'max:365'],
            'active' => ['sometimes', 'boolean'],
        ];
    }

    /** Pain à la pièce, jus à la bouteille. Un ancien jus au verre peut être modifié (désactivé) sans changer de format. */
    private function allowedFormats(mixed $category, ?Product $product): array
    {
        return match ($category) {
            ProductCategory::Bread->value => [ProductFormat::Piece->value],
            ProductCategory::Juice->value => $product?->format === ProductFormat::Glass
                ? [ProductFormat::Bottle->value, ProductFormat::Glass->value]
                : [ProductFormat::Bottle->value],
            default => [],
        };
    }
}
