<?php

namespace App\Enums;

/** Taille facultative : même produit, même qualité, quantité et prix différents (ex. pain au chocolat petit / grand). */
enum ProductSize: string
{
    case Small = 'small';
    case Medium = 'medium';
    case Large = 'large';

    /** Rang d'affichage : petit, moyen, grand. */
    public function rank(): int
    {
        return match ($this) {
            self::Small => 1,
            self::Medium => 2,
            self::Large => 3,
        };
    }
}
