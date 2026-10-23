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

    public function test_same_bread_in_two_sizes_with_its_own_price(): void
    {
        $this->actingAsOwner();
        $bread = ['category' => 'bread', 'name_fr' => 'Pain au chocolat', 'name_mg' => 'Mofo sôkôla', 'format' => 'piece', 'shelf_life_days' => 2];

        $this->postJson('/api/products', [...$bread, 'size' => 'small', 'unit_price' => 1000])
            ->assertCreated()
            ->assertJsonPath('data.size', 'small');
        $this->postJson('/api/products', [...$bread, 'size' => 'large', 'unit_price' => 1500])
            ->assertCreated()
            ->assertJsonPath('data.unit_price', 1500);

        // Même taille deux fois : refusé. Sans taille : autorisé une fois.
        $this->postJson('/api/products', [...$bread, 'size' => 'large', 'unit_price' => 1600])
            ->assertJsonValidationErrors('format');
        $this->postJson('/api/products', [...$bread, 'unit_price' => 1200])->assertCreated()->assertJsonPath('data.size', null);
        $this->postJson('/api/products', [...$bread, 'size' => null, 'unit_price' => 1200])->assertJsonValidationErrors('format');
        $this->postJson('/api/products', [...$bread, 'size' => 'huge', 'unit_price' => 1200])->assertJsonValidationErrors('size');

        // Petit, moyen, grand dans l'ordre, quel que soit l'ordre de création.
        $sizes = collect($this->getJson('/api/products')->json('data'))
            ->where('name_fr', 'Pain au chocolat')
            ->pluck('size')
            ->values()
            ->all();
        $this->assertSame([null, 'small', 'large'], $sizes);
    }

    public function test_size_appears_in_messages_in_both_languages(): void
    {
        $this->actingAsStaff();
        $large = Product::factory()->create(['name_fr' => 'Pain au chocolat', 'name_mg' => 'Mofo sôkôla', 'size' => 'large']);

        $this->postJson('/api/sales', ['items' => [['product_id' => $large->id, 'quantity' => 1]]])
            ->assertStatus(422)
            ->assertJsonPath('params.product', 'Pain au chocolat (grand)');

        $this->postJson('/api/sales', ['items' => [['product_id' => $large->id, 'quantity' => 1]]], ['Accept-Language' => 'mg'])
            ->assertJsonPath('params.product', 'Mofo sôkôla (lehibe)');
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
