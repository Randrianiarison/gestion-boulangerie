<?php

namespace App\Services;

use App\Models\Employee;
use App\Models\SalaryRate;
use Carbon\CarbonImmutable;
use Carbon\CarbonInterface;
use Illuminate\Support\Collection;

/**
 * Salaires acquis jour par jour.
 *
 * Coût d'un jour = salaire mensuel en vigueur ce jour / nombre de jours du mois,
 * uniquement entre hired_on et left_on (inclus). Les montants exacts sont
 * additionnés puis arrondis une seule fois à l'ariary : un mois complet donne
 * donc exactement le salaire mensuel.
 */
class SalaryCalculator
{
    /** Salaire acquis entre $from et $to inclus, arrondi à l'ariary. */
    public function accrued(Employee $employee, CarbonInterface $from, CarbonInterface $to): int
    {
        return (int) round($this->accruedExact($employee, $from, $to));
    }

    /** Salaire acquis entre $from et $to inclus, sans arrondi. */
    public function accruedExact(Employee $employee, CarbonInterface $from, CarbonInterface $to): float
    {
        $range = $this->workedRange($employee, $from, $to);
        if ($range === null) {
            return 0.0;
        }
        [$cursor, $end] = $range;

        $rates = $this->sortedRates($employee);
        $total = 0.0;

        // Découpe en segments où le mois et le taux sont constants.
        while ($cursor->lte($end)) {
            $segmentEnd = $cursor->endOfMonth()->startOfDay()->min($end);

            /** @var SalaryRate|null $nextChange */
            $nextChange = $rates->first(fn (SalaryRate $rate) => $rate->effective_from->gt($cursor));
            if ($nextChange !== null && $nextChange->effective_from->lte($segmentEnd)) {
                $segmentEnd = $nextChange->effective_from->subDay();
            }

            $days = (int) round($cursor->diffInDays($segmentEnd)) + 1;
            $total += $this->rateFrom($rates, $cursor) * $days / $cursor->daysInMonth;

            $cursor = $segmentEnd->addDay();
        }

        return $total;
    }

    /** Coût exact d'un jour (0 hors contrat). */
    public function dailyAmount(Employee $employee, CarbonInterface $day): float
    {
        if ($this->workedRange($employee, $day, $day) === null) {
            return 0.0;
        }

        return $this->rateOn($employee, $day) / $day->daysInMonth;
    }

    /** Salaire mensuel en vigueur ce jour (0 si aucun taux n'est encore défini). */
    public function rateOn(Employee $employee, CarbonInterface $day): int
    {
        return $this->rateFrom($this->sortedRates($employee), CarbonImmutable::instance($day)->startOfDay());
    }

    /** Total versé jusqu'à $asOf inclus. */
    public function paidTotal(Employee $employee, CarbonInterface $asOf): int
    {
        return (int) $employee->salaryPayments
            ->filter(fn ($payment) => $payment->paid_on->lte($asOf))
            ->sum('amount');
    }

    /** Solde dû = salaires acquis depuis l'embauche - paiements. Négatif = avance. */
    public function balance(Employee $employee, CarbonInterface $asOf): int
    {
        return $this->accrued($employee, $employee->hired_on, $asOf) - $this->paidTotal($employee, $asOf);
    }

    /** Salaire mensuel actuel : celui du dernier jour travaillé si l'employé est parti. */
    public function currentRate(Employee $employee, CarbonInterface $asOf): int
    {
        $day = CarbonImmutable::instance($asOf)->startOfDay();
        if ($employee->left_on !== null && $employee->left_on->lt($day)) {
            $day = $employee->left_on;
        }

        return $this->rateOn($employee, $day);
    }

    /** Mois non payés = solde dû / salaire mensuel actuel, à une décimale (ex. 2,5). */
    public function unpaidMonths(Employee $employee, CarbonInterface $asOf): ?float
    {
        return $this->monthsOf($this->balance($employee, $asOf), $this->currentRate($employee, $asOf));
    }

    /**
     * @return array{as_of: string, accrued: int, paid: int, balance: int, current_rate: int, unpaid_months: float|null}
     */
    public function summary(Employee $employee, CarbonInterface $asOf): array
    {
        $accrued = $this->accrued($employee, $employee->hired_on, $asOf);
        $paid = $this->paidTotal($employee, $asOf);
        $balance = $accrued - $paid;
        $rate = $this->currentRate($employee, $asOf);

        return [
            'as_of' => $asOf->toDateString(),
            'accrued' => $accrued,
            'paid' => $paid,
            'balance' => $balance,
            'current_rate' => $rate,
            'unpaid_months' => $this->monthsOf($balance, $rate),
        ];
    }

    private function monthsOf(int $balance, int $rate): ?float
    {
        if ($balance <= 0) {
            return 0.0;
        }

        return $rate > 0 ? round($balance / $rate, 1) : null;
    }

    /**
     * Intersection de [$from, $to] avec la période de contrat.
     *
     * @return array{0: CarbonImmutable, 1: CarbonImmutable}|null
     */
    private function workedRange(Employee $employee, CarbonInterface $from, CarbonInterface $to): ?array
    {
        $start = CarbonImmutable::instance($from)->startOfDay()->max($employee->hired_on);
        $end = CarbonImmutable::instance($to)->startOfDay();
        if ($employee->left_on !== null) {
            $end = $end->min($employee->left_on);
        }

        return $start->lte($end) ? [$start, $end] : null;
    }

    /** @return Collection<int, SalaryRate> */
    private function sortedRates(Employee $employee): Collection
    {
        return $employee->salaryRates->sortBy(fn (SalaryRate $rate) => $rate->effective_from->toDateString())->values();
    }

    /** @param  Collection<int, SalaryRate>  $rates */
    private function rateFrom(Collection $rates, CarbonImmutable $day): int
    {
        return $rates->last(fn (SalaryRate $rate) => $rate->effective_from->lte($day))?->monthly_amount ?? 0;
    }
}
