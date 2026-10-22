<?php

namespace App\Models;

use App\Casts\DateOnly;
use App\Enums\ClosingMode;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class DayClosing extends Model
{
    protected $fillable = [
        'date',
        'mode',
        'user_id',
    ];

    protected function casts(): array
    {
        return [
            'date' => DateOnly::class,
            'mode' => ClosingMode::class,
        ];
    }

    public function sales(): HasMany
    {
        return $this->hasMany(Sale::class);
    }

    public function wasteRecords(): HasMany
    {
        return $this->hasMany(WasteRecord::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
