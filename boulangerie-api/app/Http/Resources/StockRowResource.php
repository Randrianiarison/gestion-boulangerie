<?php

namespace App\Http\Resources;

use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Ligne de StockService::availabilityOn().
 *
 * @property array{product: Product, available: int, expiring: int, stale: int} $resource
 */
class StockRowResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'product' => new ProductResource($this->resource['product']),
            'available' => $this->resource['available'],
            'expiring' => $this->resource['expiring'],
            'stale' => $this->resource['stale'],
        ];
    }
}
