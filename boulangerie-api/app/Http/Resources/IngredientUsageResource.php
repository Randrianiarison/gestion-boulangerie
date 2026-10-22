<?php

namespace App\Http\Resources;

use App\Models\IngredientUsage;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin IngredientUsage */
class IngredientUsageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'ingredient_id' => $this->ingredient_id,
            'used_on' => $this->used_on->toDateString(),
            'quantity' => $this->quantity,
            'note' => $this->note,
        ];
    }
}
