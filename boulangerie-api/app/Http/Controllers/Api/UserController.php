<?php

namespace App\Http\Controllers\Api;

use App\Enums\UserRole;
use App\Exceptions\BusinessRuleException;
use App\Http\Controllers\Controller;
use App\Http\Requests\UserRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Gate;

/** Comptes de connexion (owner) : créer, réinitialiser un PIN, désactiver. */
class UserController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        Gate::authorize('viewAny', User::class);

        return UserResource::collection(User::orderByDesc('active')->orderBy('role')->orderBy('name')->get());
    }

    public function store(UserRequest $request): JsonResponse
    {
        return (new UserResource(User::create($request->validated())))->response()->setStatusCode(201);
    }

    public function update(UserRequest $request, User $user): UserResource
    {
        $data = $request->validated();

        // L'owner connecté ne peut pas se retirer ses propres droits : il reste donc toujours un owner actif.
        $losesOwnerRights = ($request->has('active') && ! $request->boolean('active'))
            || (isset($data['role']) && $data['role'] !== UserRole::Owner->value);

        if ($losesOwnerRights && $user->is($request->user())) {
            throw new BusinessRuleException('cannot_modify_self');
        }

        $user->update($data);

        // Nouveau PIN ou compte désactivé : les sessions ouvertes sur les téléphones sont fermées.
        if (isset($data['pin']) || ! $user->active) {
            $user->tokens()->delete();
        }

        return new UserResource($user);
    }
}
