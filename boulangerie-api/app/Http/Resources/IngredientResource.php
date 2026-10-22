<?php

namespace App\Http\Resources;

use App\Models\Ingredient;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Ingredient */
class IngredientResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $stock = $this->stock();

        return [
            'id' => $this->id,
            'name_fr' => $this->name_fr,
            'name_mg' => $this->name_mg,
            'unit' => $this->unit,
            'alert_threshold' => $this->alert_threshold,
            'active' => $this->active,
            'stock' => $stock,
            'low_stock' => $stock < $this->alert_threshold,
            'purchases' => IngredientPurchaseResource::collection($this->whenLoaded('purchases')),
            'usages' => IngredientUsageResource::collection($this->whenLoaded('usages')),
        ];
    }
}
