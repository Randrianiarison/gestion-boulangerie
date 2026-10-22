<?php

namespace App\Enums;

enum ClosingMode: string
{
    /** Clôture saisie à l'écran avec le comptage du soir. */
    case Counted = 'counted';
    /** Clôture de rattrapage par la commande stock:close-day, sans comptage. */
    case Automatic = 'automatic';
}
