<?php

namespace App\Http\Requests;

use App\Enums\WasteReason;
use App\Http\Requests\Concerns\ResolvesDates;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/** Invendu saisi à la main : abîmé ou autre (les expirés viennent de la clôture). */
class StoreWasteRecordRequest extends FormRequest
{
    use ResolvesDates;

    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'product_id' => ['required', 'integer', Rule::exists('products', 'id')],
            'quantity' => ['required', 'integer', 'min:1', 'max:100000'],
            'date' => ['nullable', 'date_format:Y-m-d', 'before_or_equal:today'],
            'reason' => ['required', Rule::enum(WasteReason::class)->only([WasteReason::Damaged, WasteReason::Other])],
            'recovered_amount' => ['nullable', 'integer', 'min:0', 'max:100000000'],
            'note' => ['nullable', 'string', 'max:255'],
        ];
    }
}
