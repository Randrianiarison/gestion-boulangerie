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

    public function test_juice_is_sold_by_the_bottle_each_with_its_volume_and_price(): void
    {
        $this->actingAsOwner();
        $orange = ['category' => 'juice', 'name_fr' => "Jus d'orange", 'name_mg' => 'Ranom-boasary', 'format' => 'bottle', 'shelf_life_days' => 2];

        $this->postJson('/api/products', [...$orange, 'volume_ml' => 1000, 'unit_price' => 5000])
            ->assertCreated()
            ->assertJsonPath('data.volume_ml', 1000);
        // Même jus, autre bouteille : son propre prix.
        $this->postJson('/api/products', [...$orange, 'volume_ml' => 500, 'unit_price' => 3000])->assertCreated();
        // Autre jus, même contenance : autorisé.
        $this->postJson('/api/products', [...$orange, 'name_fr' => 'Jus de coco', 'volume_ml' => 500, 'unit_price' => 3500])->assertCreated();

        // Même bouteille deux fois, bouteille sans contenance, verre, jus « à la pièce » : refusés.
        $this->postJson('/api/products', [...$orange, 'volume_ml' => 1000, 'unit_price' => 5500])->assertJsonValidationErrors('format');
        $this->postJson('/api/products', [...$orange, 'name_fr' => 'Jus de goyave', 'unit_price' => 3000])
            ->assertJsonValidationErrors(['volume_ml' => 'contenance']);
        $this->postJson('/api/products', [...$orange, 'name_fr' => 'Jus de goyave', 'format' => 'glass', 'unit_price' => 1000])
            ->assertJsonValidationErrors('format');
        $this->postJson('/api/products', [...$orange, 'name_fr' => 'Jus de goyave', 'format' => 'piece', 'volume_ml' => 500, 'unit_price' => 1000])
            ->assertJsonValidationErrors(['format', 'volume_ml']);

        // 50 cl avant 1 L.
        $volumes = collect($this->getJson('/api/products')->json('data'))
            ->where('name_fr', "Jus d'orange")
            ->pluck('volume_ml')
            ->values()
            ->all();
        $this->assertSame([500, 1000], $volumes);
    }

    public function test_bread_is_sold_by_the_piece_without_volume(): void
    {
        $this->actingAsOwner();
        $bread = ['category' => 'bread', 'name_fr' => 'Baguette', 'name_mg' => 'Mofo lava', 'unit_price' => 800, 'shelf_life_days' => 1];

        $this->postJson('/api/products', [...$bread, 'format' => 'bottle', 'volume_ml' => 500])->assertJsonValidationErrors('format');
        $this->postJson('/api/products', [...$bread, 'format' => 'piece', 'volume_ml' => 500])->assertJsonValidationErrors('volume_ml');
        $this->postJson('/api/products', [...$bread, 'format' => 'piece', 'volume_ml' => null])
            ->assertCreated()
            ->assertJsonPath('data.volume_ml', null);
    }

    public function test_old_glass_juice_can_still_be_edited_and_old_bottle_gets_its_volume(): void
    {
        $this->actingAsOwner();
        $glass = Product::factory()->glass()->create(['name_fr' => 'Jus de papaye']);
        $bottle = Product::factory()->juice()->create(['name_fr' => 'Jus de papaye', 'volume_ml' => null]);
        $payload = fn (Product $product) => [
            'category' => 'juice',
            'name_fr' => $product->name_fr,
            'name_mg' => $product->name_mg,
            'format' => $product->format->value,
            'unit_price' => $product->unit_price,
            'shelf_life_days' => $product->shelf_life_days,
            'active' => $product->active,
        ];

        // Le verre garde son format (pour l'historique) ; on peut toujours le modifier.
        $this->putJson("/api/products/{$glass->id}", [...$payload($glass), 'unit_price' => 1200])
            ->assertOk()
            ->assertJsonPath('data.format', 'glass');

        // Une bouteille d'avant reçoit sa contenance dès qu'on la modifie.
        $this->putJson("/api/products/{$bottle->id}", $payload($bottle))->assertJsonValidationErrors('volume_ml');
        $this->putJson("/api/products/{$bottle->id}", [...$payload($bottle), 'volume_ml' => 1000])
            ->assertOk()
            ->assertJsonPath('data.volume_ml', 1000);
        // Changer seulement le prix reste possible sans renvoyer la contenance.
        $this->putJson("/api/products/{$bottle->id}", ['unit_price' => 4500])->assertOk()->assertJsonPath('data.volume_ml', 1000);
    }

    public function test_volume_appears_in_messages(): void
    {
        $this->actingAsStaff();
        $orange = Product::factory()->juice(500)->create(['name_fr' => "Jus d'orange", 'name_mg' => 'Ranom-boasary']);

        $this->postJson('/api/sales', ['items' => [['product_id' => $orange->id, 'quantity' => 1]]])
            ->assertStatus(422)
            ->assertJsonPath('params.product', "Jus d'orange (50 cl)");
        $this->postJson('/api/sales', ['items' => [['product_id' => $orange->id, 'quantity' => 1]]], ['Accept-Language' => 'mg'])
            ->assertJsonPath('params.product', 'Ranom-boasary (50 cl)');

        $this->assertSame('33 cl', Product::volumeLabel(330));
        $this->assertSame('1 L', Product::volumeLabel(1000));
        $this->assertSame('1,5 L', Product::volumeLabel(1500));
        $this->assertSame('125 ml', Product::volumeLabel(125));
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
