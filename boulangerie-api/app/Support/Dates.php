<?php

namespace App\Support;

use Carbon\CarbonImmutable;

class Dates
{
    /** 'AAAA-MM-JJ' réellement existante (pas de 30 février), sinon null. */
    public static function parseIso(string $value): ?CarbonImmutable
    {
        if (! preg_match('/^(\d{4})-(\d{2})-(\d{2})$/', $value, $m) || ! checkdate((int) $m[2], (int) $m[3], (int) $m[1])) {
            return null;
        }

        return CarbonImmutable::createFromFormat('!Y-m-d', $value);
    }
}
