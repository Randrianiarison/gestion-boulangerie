<?php

namespace Database\Seeders;

use App\Enums\IngredientUnit;
use App\Enums\ProductCategory;
use App\Enums\ProductFormat;
use App\Enums\ProductSize;
use App\Enums\UserRole;
use App\Models\Ingredient;
use App\Models\Product;
use App\Models\User;
use App\Support\Phone;
use Illuminate\Database\Seeder;
use RuntimeException;

/**
 * Données de départ : comptes, catalogue et ingrédients.
 * Les noms malgaches sont à faire relire par un locuteur natif.
 */
class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Les PIN de démo sont publics (README) : jamais sur un serveur en ligne.
        if (app()->isProduction()) {
            $this->seedProductionOwner();
        } else {
            $this->seedDemoAccounts();
        }

        $this->seedProducts();
        $this->seedIngredients();
    }

    private function seedDemoAccounts(): void
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
    }

    /** Seul le propriétaire défini dans .env (SEED_OWNER_*) ; les employés se créent ensuite dans l'appli. */
    private function seedProductionOwner(): void
    {
        $owner = config('boulangerie.seed_owner');
        $phone = Phone::normalize($owner['phone']);
        $pin = (string) $owner['pin'];

        if ($phone === null || ! preg_match('/^0\d{9}$/', $phone) || ! preg_match('/^\d{4,6}$/', $pin)) {
            throw new RuntimeException(
                'En production, renseignez SEED_OWNER_PHONE (ex. 034 12 345 67) et SEED_OWNER_PIN (4 à 6 chiffres) dans .env, '
                .'puis lancez php artisan config:clear avant php artisan db:seed --force.'
            );
        }

        // firstOrCreate : relancer le seed ne remet pas l'ancien PIN si le propriétaire l'a changé dans l'appli.
        User::firstOrCreate(['phone' => $phone], [
            'name' => $owner['name'],
            'pin' => $pin,
            'role' => UserRole::Owner,
            'active' => true,
        ]);
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
            Product::updateOrCreate(['name_fr' => $fr, 'format' => ProductFormat::Piece, 'size' => null], [
                'category' => ProductCategory::Bread,
                'name_mg' => $mg,
                'unit_price' => $price,
                'shelf_life_days' => $days,
                'active' => true,
            ]);
        }

        // Même pain, même qualité, deux tailles : chacune a son prix.
        foreach ([[ProductSize::Small, 1000], [ProductSize::Large, 1500]] as [$size, $price]) {
            Product::updateOrCreate(['name_fr' => 'Pain au chocolat', 'format' => ProductFormat::Piece, 'size' => $size], [
                'category' => ProductCategory::Bread,
                'name_mg' => 'Mofo sôkôla',
                'unit_price' => $price,
                'shelf_life_days' => 2,
                'active' => true,
            ]);
        }

        $juices = [
            // name_fr, name_mg, [contenance en ml => prix] : chaque jus a sa (ou ses) bouteille(s).
            ["Jus d'orange", 'Ranom-boasary', [500 => 3000, 1000 => 5000]],
            ['Jus de coco', 'Ranom-boanio', [500 => 3000]],
            ['Jus de papaye', 'Ranom-papay', [1000 => 4000]],
            ["Jus d'avocat", 'Ranon-javoka', [500 => 4000]],
            ["Jus d'ananas", 'Ranom-mananasy', [1000 => 4000]],
        ];
        foreach ($juices as [$fr, $mg, $bottles]) {
            foreach ($bottles as $volume => $price) {
                // Jus vendu à la bouteille ; fermée, elle se garde deux jours.
                Product::updateOrCreate(['name_fr' => $fr, 'format' => ProductFormat::Bottle, 'size' => null, 'volume_ml' => $volume], [
                    'category' => ProductCategory::Juice,
                    'name_mg' => $mg,
                    'unit_price' => $price,
                    'shelf_life_days' => 2,
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
