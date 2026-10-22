<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\DateRangeRequest;
use App\Http\Requests\StoreIngredientPurchaseRequest;
use App\Http\Resources\IngredientPurchaseResource;
use App\Models\Ingredient;
use App\Models\IngredientPurchase;
use App\Services\IngredientService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

class IngredientPurchaseController extends Controller
{
    public function index(DateRangeRequest $request): AnonymousResourceCollection
    {
        Gate::authorize('viewAny', Ingredient::class);

        $purchases = IngredientPurchase::query()
            ->whereBetween('purchased_on', [$request->from()->toDateString(), $request->to()->toDateString()])
            ->when($request->filled('ingredient_id'), fn ($query) => $query->where('ingredient_id', $request->integer('ingredient_id')))
            ->orderByDesc('purchased_on')
            ->orderByDesc('id')
            ->get();

        return IngredientPurchaseResource::collection($purchases)->additional(['total' => (int) $purchases->sum('total')]);
    }

    public function store(StoreIngredientPurchaseRequest $request, IngredientService $service): JsonResponse
    {
        $purchase = $service->recordPurchase(
            Ingredient::findOrFail($request->validated('ingredient_id')),
            (float) $request->validated('quantity'),
            $request->validated('unit_price') !== null ? (int) $request->validated('unit_price') : null,
            $request->validated('total') !== null ? (int) $request->validated('total') : null,
            $request->dateOrToday('purchased_on'),
            $request->validated('supplier'),
            $request->user(),
        );

        return (new IngredientPurchaseResource($purchase))->response()->setStatusCode(201);
    }

    public function destroy(IngredientPurchase $ingredientPurchase): Response
    {
        Gate::authorize('deleteMovement', Ingredient::class);
        $ingredientPurchase->delete();

        return response()->noContent();
    }
}
