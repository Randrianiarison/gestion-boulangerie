<?php

namespace App\Enums;

enum ExpenseCategory: string
{
    case Electricity = 'electricity';
    case Rent = 'rent';
    case Transport = 'transport';
    case Packaging = 'packaging';
    case Other = 'other';

    /** Catégories facturées au mois : period_month obligatoire. */
    public function isMonthly(): bool
    {
        return in_array($this, [self::Electricity, self::Rent], true);
    }
}
