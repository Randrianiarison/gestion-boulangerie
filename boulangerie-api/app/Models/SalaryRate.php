<?php

namespace App\Models;

use App\Casts\DateOnly;
use Database\Factories\SalaryRateFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SalaryRate extends Model
{
    /** @use HasFactory<SalaryRateFactory> */
    use HasFactory;

    protected $fillable = [
        'employee_id',
        'monthly_amount',
        'effective_from',
    ];

    protected function casts(): array
    {
        return [
            'monthly_amount' => 'integer',
            'effective_from' => DateOnly::class,
        ];
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class);
    }
}
