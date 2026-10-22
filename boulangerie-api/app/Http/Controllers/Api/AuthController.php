<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\BusinessRuleException;
use App\Http\Controllers\Controller;
use App\Http\Requests\LoginRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function login(LoginRequest $request): JsonResponse
    {
        $user = User::where('phone', $request->validated('phone'))->first();

        if ($user === null || ! Hash::check($request->validated('pin'), $user->pin)) {
            throw new BusinessRuleException('invalid_credentials');
        }

        if (! $user->active) {
            throw new BusinessRuleException('account_disabled', status: 403);
        }

        $token = $user->createToken($request->validated('device_name') ?? 'mobile')->plainTextToken;

        return response()->json(['data' => [
            'token' => $token,
            'user' => new UserResource($user),
        ]]);
    }

    public function logout(Request $request): Response
    {
        $request->user()->currentAccessToken()->delete();

        return response()->noContent();
    }

    public function me(Request $request): UserResource
    {
        return new UserResource($request->user());
    }
}
