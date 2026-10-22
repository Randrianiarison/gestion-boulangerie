<?php

namespace Tests\Feature;

use App\Models\Product;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProductTest extends TestCase
{
    use RefreshDatabase;

    public function test_staff_lists_products_but_cannot_change_them(): void
    {
        $this->actingAsStaff();
        $product = Product::factory()->create();
        Product::factory()->create(['active' => false]);

        $this->getJson('/api/products?active=1')->assertOk()->assertJsonCount(1, 'data');
        $this->putJson("/api/products/{$product->id}", ['unit_price' => 1])->assertForbidden();
    }

    public function test_owner_creates_a_juice_in_two_formats(): void
    {
        $this->actingAsOwner();
        $juice = ['category' => 'juice', 'name_fr' => 'Jus de goyave', 'name_mg' => 'Ranom-goavy', 'shelf_life_days' => 1];

        $this->postJson('/api/products', [...$juice, 'format' => 'glass', 'unit_price' => 1000])
            ->assertCreated()
            ->assertJsonPath('data.format', 'glass');
        $this->postJson('/api/products', [...$juice, 'format' => 'bottle', 'unit_price' => 3000])->assertCreated();

        $this->postJson('/api/products', [...$juice, 'format' => 'glass', 'unit_price' => 1200])
            ->assertJsonValidationErrors('format');
    }

    public function test_a_product_with_history_is_deactivated_not_deleted(): void
    {
        $this->actingAsOwner();
        $product = Product::factory()->create();
        $this->lot($product, now()->toDateString(), 5);

        $this->deleteJson("/api/products/{$product->id}")
            ->assertStatus(409)
            ->assertJsonPath('code', 'product_has_history');

        $this->patchJson("/api/products/{$product->id}", ['active' => false])
            ->assertOk()
            ->assertJsonPath('data.active', false);
    }
}
