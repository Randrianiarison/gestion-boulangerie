<?php

namespace App\Http\Controllers\Api;

use App\Enums\WasteReason;
use App\Http\Controllers\Controller;
use App\Http\Requests\DateRangeRequest;
use App\Http\Requests\StoreWasteRecordRequest;
use App\Http\Requests\UpdateWasteRecordRequest;
use App\Http\Resources\WasteRecordResource;
use App\Models\Product;
use App\Models\WasteRecord;
use App\Services\WasteService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class WasteRecordController extends Controller
{
    public function index(DateRangeRequest $request): AnonymousResourceCollection
    {
        $records = WasteRecord::with('product')
            ->whereBetween('date', [$request->from()->toDateString(), $request->to()->toDateString()])
            ->when($request->filled('product_id'), fn ($query) => $query->where('product_id', $request->integer('product_id')))
            ->orderByDesc('date')
            ->orderByDesc('id')
            ->get();

        return WasteRecordResource::collection($records)->additional(['summary' => [
            'quantity' => (int) $records->sum('quantity'),
            'lost_value' => (int) $records->sum(fn (WasteRecord $record) => $record->lostValue()),
            'recovered' => (int) $records->sum('recovered_amount'),
        ]]);
    }

    /** Invendu abîmé ou autre, saisi à la main. */
    public function store(StoreWasteRecordRequest $request, WasteService $service): JsonResponse
    {
        $product = Product::findOrFail($request->validated('product_id'));

        $records = $service->record(
            $product,
            $request->validated('quantity'),
            $request->dateOrToday('date'),
            WasteReason::from($request->validated('reason')),
            (int) $request->validated('recovered_amount', 0),
            $request->validated('note'),
            $request->user(),
        );

        return WasteRecordResource::collection($records->each->setRelation('product', $product))
            ->response()
            ->setStatusCode(201);
    }

    /** Montant récupéré (revente à prix réduit) ou remarque, renseignés après coup. */
    public function update(UpdateWasteRecordRequest $request, WasteRecord $wasteRecord): WasteRecordResource
    {
        $wasteRecord->update($request->validated());

        return new WasteRecordResource($wasteRecord->load('product'));
    }
}
