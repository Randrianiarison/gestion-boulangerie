<?php

namespace Database\Seeders;

use App\Enums\IngredientUnit;
use App\Enums\ProductCategory;
use App\Enums\ProductFormat;
use App\Enums\UserRole;
use App\Models\Ingredient;
use App\Models\Product;
use App\Models\User;
use Illuminate\Database\Seeder;

/**
 * Données de départ : comptes de démo, catalogue et ingrédients.
 * Les noms malgaches sont à faire relire par un locuteur natif.
 */
class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        User::updateOrCreate(['phone' => '0340000001'], [
            'name' => 'Propriétaire',
            'pin' => '1234',
            'role' => UserRole::Owner,
            'active' => true,
        ]);
        User::updateOrCreate(['phone' => '0340000002'], [
            'name' => 'Vendeur',
            'pin' => '5678',
            'role' => UserRole::Staff,
            'active' => true,
        ]);

        $this->seedProducts();
        $this->seedIngredients();
    }

    private function seedProducts(): void
    {
        $breads = [
            // name_fr, name_mg, prix, conservation (jours)
            ['Baguette', 'Mofo lava', 800, 1],
            ['Petit pain', 'Mofo kely', 300, 1],
            ['Pain de mie', 'Mofo malefaka', 3000, 3],
            ['Pain au beurre', 'Mofo dibera', 1000, 3],
        ];
        foreach ($breads as [$fr, $mg, $price, $days]) {
            Product::updateOrCreate(['name_fr' => $fr, 'format' => ProductFormat::Piece], [
                'category' => ProductCategory::Bread,
                'name_mg' => $mg,
                'unit_price' => $price,
                'shelf_life_days' => $days,
                'active' => true,
            ]);
        }

        $juices = [
            // name_fr, name_mg, prix verre, prix bouteille
            ['Jus de papaye', 'Ranom-papay', 1000, 3000],
            ["Jus d'avocat", 'Ranon-javoka', 1500, 4000],
            ["Jus d'ananas", 'Ranom-mananasy', 1000, 3000],
        ];
        foreach ($juices as [$fr, $mg, $glassPrice, $bottlePrice]) {
            // Le verre se boit le jour même, la bouteille fermée se garde deux jours.
            foreach ([[ProductFormat::Glass, $glassPrice, 1], [ProductFormat::Bottle, $bottlePrice, 2]] as [$format, $price, $days]) {
                Product::updateOrCreate(['name_fr' => $fr, 'format' => $format], [
                    'category' => ProductCategory::Juice,
                    'name_mg' => $mg,
                    'unit_price' => $price,
                    'shelf_life_days' => $days,
                    'active' => true,
                ]);
            }
        }
    }

    private function seedIngredients(): void
    {
        $ingredients = [
            // name_fr, name_mg, unité, seuil d'alerte
            ['Farine', 'Lafarinina', IngredientUnit::Kg, 25],
            ['Huile', 'Menaka', IngredientUnit::Litre, 5],
            ['Beurre', 'Dibera', IngredientUnit::Kg, 2],
            ['Sucre', 'Siramamy', IngredientUnit::Kg, 10],
            ['Levure', 'Levira', IngredientUnit::Sachet, 10],
            ['Sel', 'Sira', IngredientUnit::Kg, 2],
            ['Papaye', 'Papay', IngredientUnit::Piece, 10],
            ['Avocat', 'Zavoka', IngredientUnit::Piece, 10],
            ['Ananas', 'Mananasy', IngredientUnit::Piece, 5],
        ];
        foreach ($ingredients as [$fr, $mg, $unit, $threshold]) {
            Ingredient::updateOrCreate(['name_fr' => $fr], [
                'name_mg' => $mg,
                'unit' => $unit,
                'alert_threshold' => $threshold,
                'active' => true,
            ]);
        }
    }
}
