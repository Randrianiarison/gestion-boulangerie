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
        $size = $this->exists('size') ? $this->input('size') : $product?->size?->value;

        return [
            'category' => [$required, Rule::enum(ProductCategory::class)],
            'name_fr' => [$required, 'string', 'max:100'],
            'name_mg' => [$required, 'string', 'max:100'],
            // Un seul « Pain au chocolat » par format et par taille (sans taille compte comme une taille).
            'format' => [
                $required,
                Rule::enum(ProductFormat::class),
                Rule::unique('products')
                    ->where('name_fr', $this->input('name_fr', $product?->name_fr))
                    ->where(fn ($query) => $size === null ? $query->whereNull('size') : $query->where('size', $size))
                    ->ignore($product),
            ],
            'size' => ['sometimes', 'nullable', Rule::enum(ProductSize::class)],
            'unit_price' => [$required, 'integer', 'min:0', 'max:10000000'],
            'shelf_life_days' => [$required, 'integer', 'min:1', 'max:365'],
            'active' => ['sometimes', 'boolean'],
        ];
    }
}
