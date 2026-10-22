<?php

namespace App\Http\Requests;

use App\Models\DayClosing;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class CloseDayRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', DayClosing::class);
    }

    public function rules(): array
    {
        return [
            // Liste vide possible : rien en stock ce jour-là, on clôture seulement les lots expirés.
            'items' => ['present', 'array'],
            'items.*.product_id' => ['required', 'integer', 'distinct', Rule::exists('products', 'id')],
            'items.*.remaining' => ['required', 'integer', 'min:0', 'max:100000'],
            'items.*.recovered_amount' => ['nullable', 'integer', 'min:0', 'max:100000000'],
        ];
    }
}
