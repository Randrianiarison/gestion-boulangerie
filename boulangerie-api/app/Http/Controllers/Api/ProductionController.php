<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\BusinessRuleException;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreProductionRequest;
use App\Http\Resources\StockLotResource;
use App\Models\Product;
use App\Models\StockLot;
use App\Services\DayLock;
use App\Services\StockService;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;

class ProductionController extends Controller
{
    public function __construct(
        private readonly StockService $stock,
        private readonly DayLock $lock,
    ) {}

    /** Lots produits un jour donné (aujourd'hui par défaut). */
    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate(['date' => ['nullable', 'date_format:Y-m-d']]);
        $date = $request->filled('date') ? CarbonImmutable::parse($request->input('date')) : CarbonImmutable::today();

        $lots = StockLot::with('product')
            ->where('produced_on', $date->toDateString())
            ->orderBy('id')
            ->get();

        return StockLotResource::collection($lots)->additional(['date' => $date->toDateString()]);
    }

    /** Production du matin : un lot par produit saisi. */
    public function store(StoreProductionRequest $request): JsonResponse
    {
        $date = $request->dateOrToday('produced_on');
        $items = $request->validated('items');

        $lots = DB::transaction(function () use ($date, $items, $request) {
            $this->lock->assertOpen($date);
            $products = Product::findMany(array_column($items, 'product_id'))->keyBy('id');

            return collect($items)->map(
                fn (array $item) => $this->stock
                    ->produce($products[$item['product_id']], $item['quantity'], $date, $request->user())
                    ->setRelation('product', $products[$item['product_id']])
            );
        });

        return StockLotResource::collection($lots)->response()->setStatusCode(201);
    }

    /** Corriger une erreur de saisie : seulement si rien n'a encore été vendu ni jeté. */
    public function destroy(StockLot $stockLot): Response
    {
        $used = $stockLot->quantity_remaining !== $stockLot->quantity_produced
            || $stockLot->allocations()->exists()
            || $stockLot->wasteRecords()->exists();

        if ($used) {
            throw new BusinessRuleException('lot_already_used', status: 409);
        }

        $this->lock->assertOpen($stockLot->produced_on);
        $stockLot->delete();

        return response()->noContent();
    }
}
