<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\DateRangeRequest;
use App\Http\Requests\StoreSaleRequest;
use App\Http\Resources\SaleResource;
use App\Models\Sale;
use App\Services\SaleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class SaleController extends Controller
{
    public function index(DateRangeRequest $request): AnonymousResourceCollection
    {
        $sales = Sale::with('product')
            ->whereBetween('sold_on', [$request->from()->toDateString(), $request->to()->toDateString()])
            ->when($request->filled('product_id'), fn ($query) => $query->where('product_id', $request->integer('product_id')))
            ->orderByDesc('sold_on')
            ->orderByDesc('id')
            ->get();

        return SaleResource::collection($sales)->additional(['summary' => [
            'from' => $request->from()->toDateString(),
            'to' => $request->to()->toDateString(),
            'count' => $sales->count(),
            'quantity' => (int) $sales->sum('quantity'),
            'total' => (int) $sales->sum('total'),
        ]]);
    }

    /** Vente directe au comptoir, au prix du jour. */
    public function store(StoreSaleRequest $request, SaleService $service): JsonResponse
    {
        $sales = $service->recordCounterSales(
            $request->dateOrToday('sold_on'),
            $request->validated('items'),
            $request->user(),
        );

        return SaleResource::collection($sales)
            ->additional(['total' => (int) $sales->sum('total')])
            ->response()
            ->setStatusCode(201);
    }
}
