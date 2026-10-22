<?php

namespace App\Http\Resources;

use App\Models\WasteRecord;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin WasteRecord */
class WasteRecordResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'product_id' => $this->product_id,
            'product' => new ProductResource($this->whenLoaded('product')),
            'stock_lot_id' => $this->stock_lot_id,
            'date' => $this->date->toDateString(),
            'quantity' => $this->quantity,
            'reason' => $this->reason,
            'unit_price' => $this->unit_price,
            'lost_value' => $this->lostValue(),
            'recovered_amount' => $this->recovered_amount,
            'note' => $this->note,
        ];
    }
}
