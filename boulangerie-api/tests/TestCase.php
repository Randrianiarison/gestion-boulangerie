<?php

namespace Tests;

use App\Models\Product;
use App\Models\StockLot;
use App\Models\User;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Laravel\Sanctum\Sanctum;

abstract class TestCase extends BaseTestCase
{
    protected function actingAsOwner(): User
    {
        $owner = User::factory()->owner()->create();
        Sanctum::actingAs($owner);

        return $owner;
    }

    protected function actingAsStaff(): User
    {
        $staff = User::factory()->staff()->create();
        Sanctum::actingAs($staff);

        return $staff;
    }

    /** Lot déjà en stock, sans passer par l'API. */
    protected function lot(Product $product, string $producedOn, int $quantity): StockLot
    {
        return StockLot::factory()->for($product)->producedOn($producedOn, $quantity)->create();
    }
}
