<?php

namespace App\Http\Requests;

use App\Http\Requests\Concerns\ResolvesDates;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Gate;

class ReportRequest extends FormRequest
{
    use ResolvesDates;

    public function authorize(): bool
    {
        return Gate::allows('view-reports');
    }

    public function rules(): array
    {
        return [
            'period' => ['required', 'in:week,month'],
            'date' => ['nullable', 'date_format:Y-m-d'],
        ];
    }
}
