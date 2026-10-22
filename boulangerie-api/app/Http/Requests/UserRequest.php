<?php

namespace App\Http\Requests;

use App\Enums\UserRole;
use App\Models\User;
use App\Support\Phone;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/** Comptes gérés par l'owner : créer un compte, réinitialiser un PIN, désactiver. */
class UserRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->route('user');

        return $user
            ? $this->user()->can('update', $user)
            : $this->user()->can('create', User::class);
    }

    protected function prepareForValidation(): void
    {
        if ($this->filled('phone')) {
            $this->merge(['phone' => Phone::normalize((string) $this->input('phone'))]);
        }
    }

    public function rules(): array
    {
        /** @var User|null $user */
        $user = $this->route('user');
        $required = $user ? 'sometimes' : 'required';

        return [
            'name' => [$required, 'string', 'max:100'],
            'phone' => [$required, 'string', 'regex:/^0\d{9}$/', Rule::unique('users', 'phone')->ignore($user)],
            'pin' => [$required, 'string', 'regex:/^\d{4,6}$/'],
            'role' => [$required, Rule::enum(UserRole::class)],
            'active' => ['sometimes', 'boolean'],
        ];
    }
}
