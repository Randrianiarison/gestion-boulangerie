<?php

namespace App\Policies;

use App\Models\User;

/** Catalogue visible par tous, modifiable par les owners (prix, seuils). */
abstract class CatalogPolicy
{
    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user): bool
    {
        return true;
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
