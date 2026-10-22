<?php

namespace App\Models;

use App\Casts\DateOnly;
use App\Enums\EmployeeRole;
use Carbon\CarbonInterface;
use Database\Factories\EmployeeFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Employee extends Model
{
    /** @use HasFactory<EmployeeFactory> */
    use HasFactory;

    protected $fillable = [
        'name',
        'phone',
        'role',
        'hired_on',
        'left_on',
    ];

    /**
     * Résumé du SalaryCalculator (solde dû, mois non payés…), calculé par le contrôleur, jamais enregistré.
     *
     * @var array<string, int|float|null>|null
     */
    public ?array $salarySummary = null;

    protected function casts(): array
    {
        return [
            'role' => EmployeeRole::class,
            'hired_on' => DateOnly::class,
            'left_on' => DateOnly::class,
        ];
    }

    public function salaryRates(): HasMany
    {
        return $this->hasMany(SalaryRate::class)->orderBy('effective_from');
    }

    public function salaryPayments(): HasMany
    {
        return $this->hasMany(SalaryPayment::class)->orderByDesc('paid_on')->orderByDesc('id');
    }

    /** Employés présents au moins un jour sur la période. */
    public function scopeEmployedBetween(Builder $query, CarbonInterface $from, CarbonInterface $to): void
    {
        $query->where('hired_on', '<=', $to->toDateString())
            ->where(fn (Builder $q) => $q->whereNull('left_on')->orWhere('left_on', '>=', $from->toDateString()));
    }
}
