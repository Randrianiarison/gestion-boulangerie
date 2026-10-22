<?php

namespace App\Policies;

use App\Models\User;

/** Base des ressources réservées aux propriétaires (salaires, dépenses, comptes). */
abstract class OwnerOnlyPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isOwner();
    }

    public function view(User $user): bool
    {
        return $user->isOwner();
    }

    public function create(User $user): bool
    {
        return $user->isOwner();
    }

    public function update(User $user): bool
    {
        return $user->isOwner();
    }

    public function delete(User $user): bool
    {
        return $user->isOwner();
    }
}
