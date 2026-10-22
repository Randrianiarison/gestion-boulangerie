<?php

namespace App\Policies;

use App\Models\User;

class DayClosingPolicy
{
    public function create(User $user): bool
    {
        return true;
    }

    /** Annuler une clôture pour recompter : owner uniquement. */
    public function delete(User $user): bool
    {
        return $user->isOwner();
    }
}
