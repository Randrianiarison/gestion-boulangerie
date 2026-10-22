<?php

namespace App\Enums;

enum SaleSource: string
{
    /** Vente directe au comptoir. */
    case Counter = 'counter';
    /** Vente déduite à la clôture : disponible - restant compté. */
    case Closing = 'closing';
}
