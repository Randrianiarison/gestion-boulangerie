<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\StockRowResource;
use App\Services\StockService;
use Carbon\CarbonImmutable;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class StockController extends Controller
{
    /** Disponible par produit (aujourd'hui par défaut, ?date=AAAA-MM-JJ sinon). */
    public function index(Request $request, StockService $stock): AnonymousResourceCollection
    {
        $request->validate(['date' => ['nullable', 'date_format:Y-m-d']]);
        $date = $request->filled('date') ? CarbonImmutable::parse($request->input('date')) : CarbonImmutable::today();

        return StockRowResource::collection($stock->availabilityOn($date, includeEmptyActive: true))
            ->additional(['date' => $date->toDateString()]);
    }
}
