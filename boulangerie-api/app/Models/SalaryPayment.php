<?php

namespace App\Models;

use App\Casts\DateOnly;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SalaryPayment extends Model
{
    protected $fillable = [
        'employee_id',
        'amount',
        'paid_on',
        'note',
        'user_id',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'integer',
            'paid_on' => DateOnly::class,
        ];
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class);
    }
}
