<?php

namespace App\Http\Resources;

use App\Models\IngredientPurchase;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin IngredientPurchase */
class IngredientPurchaseResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'ingredient_id' => $this->ingredient_id,
            'purchased_on' => $this->purchased_on->toDateString(),
            'quantity' => $this->quantity,
            'unit_price' => $this->unit_price,
            'total' => $this->total,
            'supplier' => $this->supplier,
        ];
    }
}
