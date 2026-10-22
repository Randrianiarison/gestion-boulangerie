<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/** Montant récupéré renseigné après coup (pain de la veille revendu à prix réduit). */
class UpdateWasteRecordRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'recovered_amount' => ['sometimes', 'integer', 'min:0', 'max:100000000'],
            'note' => ['sometimes', 'nullable', 'string', 'max:255'],
        ];
    }
}
