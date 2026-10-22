<?php

namespace App\Http\Requests\Concerns;

use Carbon\CarbonImmutable;

trait ResolvesDates
{
    /** Date 'Y-m-d' saisie, ou aujourd'hui si le champ est vide. */
    public function dateOrToday(string $key): CarbonImmutable
    {
        $value = $this->input($key);

        return $value ? CarbonImmutable::parse($value)->startOfDay() : CarbonImmutable::today();
    }
}
