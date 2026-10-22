<?php

namespace App\Policies;

use App\Models\User;

class IngredientPolicy extends CatalogPolicy
{
    /** Achats et utilisations : saisis aussi par le staff (ceux qui vont au marché). */
    public function recordMovement(User $user): bool
    {
        return true;
    }

    /** Supprimer un achat ou une utilisation : owner uniquement. */
    public function deleteMovement(User $user): bool
    {
        return $user->isOwner();
    }
}
