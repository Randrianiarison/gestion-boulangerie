<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\BusinessRuleException;
use App\Http\Controllers\Controller;
use App\Http\Requests\IngredientRequest;
use App\Http\Resources\IngredientResource;
use App\Models\Ingredient;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

class IngredientController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        Gate::authorize('viewAny', Ingredient::class);

        $ingredients = Ingredient::withStock()
            ->when($request->boolean('active'), fn ($query) => $query->where('active', true))
            ->orderBy('name_fr')
            ->get();

        return IngredientResource::collection($ingredients);
    }

    /** Stock des ingrédients actifs, ceux sous le seuil d'alerte en premier. */
    public function stock(): AnonymousResourceCollection
    {
        Gate::authorize('viewAny', Ingredient::class);

        $ingredients = Ingredient::withStock()
            ->where('active', true)
            ->orderBy('name_fr')
            ->get()
            ->sortBy(fn (Ingredient $ingredient) => $ingredient->isBelowThreshold() ? 0 : 1)
            ->values();

        return IngredientResource::collection($ingredients)->additional([
            'alerts_count' => $ingredients->filter->isBelowThreshold()->count(),
        ]);
    }

    public function store(IngredientRequest $request): IngredientResource
    {
        return new IngredientResource(Ingredient::create($request->validated()));
    }

    /** Fiche ingrédient avec ses 20 derniers achats et utilisations. */
    public function show(Ingredient $ingredient): IngredientResource
    {
        Gate::authorize('view', $ingredient);

        $ingredient->loadSum('purchases', 'quantity')
            ->loadSum('usages', 'quantity')
            ->load([
                'purchases' => fn ($query) => $query->orderByDesc('purchased_on')->orderByDesc('id')->limit(20),
                'usages' => fn ($query) => $query->orderByDesc('used_on')->orderByDesc('id')->limit(20),
            ]);

        return new IngredientResource($ingredient);
    }

    public function update(IngredientRequest $request, Ingredient $ingredient): IngredientResource
    {
        $ingredient->update($request->validated());

        return new IngredientResource($ingredient->loadSum('purchases', 'quantity')->loadSum('usages', 'quantity'));
    }

    public function destroy(Ingredient $ingredient): Response
    {
        Gate::authorize('delete', $ingredient);

        if ($ingredient->purchases()->exists() || $ingredient->usages()->exists()) {
            throw new BusinessRuleException('ingredient_has_history', status: 409);
        }

        $ingredient->delete();

        return response()->noContent();
    }
}
