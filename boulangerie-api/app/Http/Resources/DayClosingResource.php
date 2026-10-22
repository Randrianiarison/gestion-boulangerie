<?php

namespace App\Http\Resources;

use App\Models\DayClosing;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin DayClosing */
class DayClosingResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'date' => $this->date->toDateString(),
            'mode' => $this->mode,
            'closed_by' => $this->user?->name,
            'closed_at' => $this->created_at?->toIso8601String(),
            'sales_total' => (int) $this->sales->sum('total'),
            'waste_quantity' => (int) $this->wasteRecords->sum('quantity'),
            'waste_value' => (int) $this->wasteRecords->sum(fn ($record) => $record->lostValue()),
            'recovered_total' => (int) $this->wasteRecords->sum('recovered_amount'),
            'sales' => SaleResource::collection($this->sales),
            'waste_records' => WasteRecordResource::collection($this->wasteRecords),
        ];
    }
}
