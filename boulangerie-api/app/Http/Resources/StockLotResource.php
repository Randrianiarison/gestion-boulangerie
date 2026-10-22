<?php

namespace App\Http\Resources;

use App\Models\StockLot;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin StockLot */
class StockLotResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'product_id' => $this->product_id,
            'product' => new ProductResource($this->whenLoaded('product')),
            'produced_on' => $this->produced_on->toDateString(),
            'expires_on' => $this->expires_on->toDateString(),
            'quantity_produced' => $this->quantity_produced,
            'quantity_remaining' => $this->quantity_remaining,
            'untouched' => $this->quantity_remaining === $this->quantity_produced,
        ];
    }
}
