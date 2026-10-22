<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\DateRangeRequest;
use App\Http\Requests\StoreIngredientUsageRequest;
use App\Http\Resources\IngredientUsageResource;
use App\Models\Ingredient;
use App\Models\IngredientUsage;
use App\Services\IngredientService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

class IngredientUsageController extends Controller
{
    public function index(DateRangeRequest $request): AnonymousResourceCollection
    {
        Gate::authorize('viewAny', Ingredient::class);

        $usages = IngredientUsage::query()
            ->whereBetween('used_on', [$request->from()->toDateString(), $request->to()->toDateString()])
            ->when($request->filled('ingredient_id'), fn ($query) => $query->where('ingredient_id', $request->integer('ingredient_id')))
            ->orderByDesc('used_on')
            ->orderByDesc('id')
            ->get();

        return IngredientUsageResource::collection($usages);
    }

    public function store(StoreIngredientUsageRequest $request, IngredientService $service): JsonResponse
    {
        $usage = $service->recordUsage(
            Ingredient::findOrFail($request->validated('ingredient_id')),
            (float) $request->validated('quantity'),
            $request->dateOrToday('used_on'),
            $request->validated('note'),
            $request->user(),
        );

        return (new IngredientUsageResource($usage))->response()->setStatusCode(201);
    }

    public function destroy(IngredientUsage $ingredientUsage): Response
    {
        Gate::authorize('deleteMovement', Ingredient::class);
        $ingredientUsage->delete();

        return response()->noContent();
    }
}
