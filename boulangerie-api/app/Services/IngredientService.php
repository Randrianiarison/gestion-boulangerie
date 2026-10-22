<?php

namespace App\Services;

use App\Exceptions\BusinessRuleException;
use App\Models\Ingredient;
use App\Models\IngredientPurchase;
use App\Models\IngredientUsage;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;

class IngredientService
{
    /**
     * Achat : on saisit la quantité et soit le prix unitaire, soit le total payé (ce qu'on retient au marché).
     * Le total est la valeur retenue pour les charges.
     */
    public function recordPurchase(
        Ingredient $ingredient,
        float $quantity,
        ?int $unitPrice,
        ?int $total,
        CarbonImmutable $date,
        ?string $supplier,
        ?User $user,
    ): IngredientPurchase {
        $total ??= (int) round($quantity * $unitPrice);
        $unitPrice ??= (int) round($total / $quantity);

        return IngredientPurchase::create([
            'ingredient_id' => $ingredient->id,
            'purchased_on' => $date,
            'quantity' => $quantity,
            'unit_price' => $unitPrice,
            'total' => $total,
            'supplier' => $supplier,
            'user_id' => $user?->id,
        ]);
    }

    /** @throws BusinessRuleException insufficient_ingredient */
    public function recordUsage(Ingredient $ingredient, float $quantity, CarbonImmutable $date, ?string $note, ?User $user): IngredientUsage
    {
        return DB::transaction(function () use ($ingredient, $quantity, $date, $note, $user) {
            $ingredient = Ingredient::query()->whereKey($ingredient->id)->lockForUpdate()->firstOrFail();
            $stock = $ingredient->stock();

            if ($quantity > $stock + 0.0005) {
                throw new BusinessRuleException('insufficient_ingredient', [
                    'ingredient' => $ingredient->displayName(),
                    'available' => rtrim(rtrim(number_format($stock, 3, ',', ' '), '0'), ','),
                    'unit' => __('messages.units.'.$ingredient->unit->value),
                ]);
            }

            return IngredientUsage::create([
                'ingredient_id' => $ingredient->id,
                'used_on' => $date,
                'quantity' => $quantity,
                'note' => $note,
                'user_id' => $user?->id,
            ]);
        });
    }
}
