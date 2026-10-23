<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\BusinessRuleException;
use App\Http\Controllers\Controller;
use App\Http\Requests\ProductRequest;
use App\Http\Resources\ProductResource;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

class ProductController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        Gate::authorize('viewAny', Product::class);

        $products = Product::query()
            ->when($request->boolean('active'), fn ($query) => $query->active())
            ->catalogOrder()
            ->get();

        return ProductResource::collection($products);
    }

    public function store(ProductRequest $request): ProductResource
    {
        return new ProductResource(Product::create($request->validated()));
    }

    public function show(Product $product): ProductResource
    {
        Gate::authorize('view', $product);

        return new ProductResource($product);
    }

    public function update(ProductRequest $request, Product $product): ProductResource
    {
        $product->update($request->validated());

        return new ProductResource($product);
    }

    /** Un produit déjà produit ou vendu se désactive (active = false), il ne se supprime pas. */
    public function destroy(Product $product): Response
    {
        Gate::authorize('delete', $product);

        if ($product->stockLots()->exists() || $product->sales()->exists()) {
            throw new BusinessRuleException('product_has_history', status: 409);
        }

        $product->delete();

        return response()->noContent();
    }
}
