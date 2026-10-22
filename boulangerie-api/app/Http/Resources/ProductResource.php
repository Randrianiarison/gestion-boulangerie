<?php

namespace App\Http\Resources;

use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Product */
class ProductResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'category' => $this->category,
            'name_fr' => $this->name_fr,
            'name_mg' => $this->name_mg,
            'format' => $this->format,
            'unit_price' => $this->unit_price,
            'shelf_life_days' => $this->shelf_life_days,
            'active' => $this->active,
        ];
    }
}
