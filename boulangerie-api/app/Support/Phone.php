<?php

namespace App\Support;

class Phone
{
    /**
     * Normalise un numéro malgache : "+261 34 12 345 67" et "034 12 345 67" donnent "0341234567".
     */
    public static function normalize(?string $phone): ?string
    {
        if ($phone === null) {
            return null;
        }

        $digits = preg_replace('/[^\d+]/', '', $phone);

        if (str_starts_with($digits, '+261')) {
            $digits = '0'.substr($digits, 4);
        } elseif (str_starts_with($digits, '261') && strlen($digits) === 12) {
            $digits = '0'.substr($digits, 3);
        }

        return $digits;
    }
}
