<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\MassPrunable;
use Illuminate\Database\Eloquent\Model;

/** Réponse déjà envoyée pour une opération du téléphone, rejouée si l'opération revient. */
class IdempotencyKey extends Model
{
    use MassPrunable;

    protected $fillable = [
        'user_id',
        'key',
        'status_code',
        'response',
    ];

    protected function casts(): array
    {
        return [
            'status_code' => 'integer',
        ];
    }

    /** Un téléphone renvoie ses opérations en quelques jours au plus : 30 jours suffisent (php artisan model:prune). */
    public function prunable(): Builder
    {
        return static::where('created_at', '<', now()->subDays(30));
    }
}
