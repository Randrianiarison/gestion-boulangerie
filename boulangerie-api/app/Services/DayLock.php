<?php

namespace App\Services;

use App\Exceptions\BusinessRuleException;
use App\Models\DayClosing;
use Carbon\CarbonImmutable;

/**
 * Une journée clôturée est figée : plus de production, vente ni invendu à cette date ou avant.
 * Les clôtures se font donc dans l'ordre chronologique.
 */
class DayLock
{
    public function lastClosedDate(): ?CarbonImmutable
    {
        $last = DayClosing::max('date');

        return $last ? CarbonImmutable::parse($last)->startOfDay() : null;
    }

    /** Code d'erreur si la date est verrouillée (future_date, day_closed, period_closed), sinon null. */
    public function blockedReason(CarbonImmutable $date): ?string
    {
        if ($date->gt(CarbonImmutable::today())) {
            return 'future_date';
        }

        $last = $this->lastClosedDate();
        if ($last === null || $date->gt($last)) {
            return null;
        }

        return $date->eq($last) ? 'day_closed' : 'period_closed';
    }

    /** @throws BusinessRuleException */
    public function assertOpen(CarbonImmutable $date): void
    {
        $reason = $this->blockedReason($date);
        if ($reason === null) {
            return;
        }

        throw new BusinessRuleException($reason, [
            'date' => $date->toDateString(),
            'last' => $this->lastClosedDate()?->toDateString() ?? '',
        ]);
    }
}
