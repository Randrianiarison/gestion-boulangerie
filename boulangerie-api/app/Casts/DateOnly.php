<?php

namespace App\Casts;

use Carbon\CarbonImmutable;
use DateTimeInterface;
use Illuminate\Contracts\Database\Eloquent\CastsAttributes;
use Illuminate\Contracts\Database\Eloquent\SerializesCastableAttributes;
use Illuminate\Database\Eloquent\Model;

/**
 * Date sans heure, stockée en 'Y-m-d' quel que soit le moteur.
 *
 * Le cast 'date' d'Eloquent écrit 'Y-m-d H:i:s' : sous SQLite, la comparaison
 * de chaînes avec '2026-10-22' devient alors fausse. Ce cast garde les
 * requêtes `where('sold_on', '<=', $date->toDateString())` identiques en MySQL et SQLite.
 *
 * @implements CastsAttributes<CarbonImmutable, string>
 */
class DateOnly implements CastsAttributes, SerializesCastableAttributes
{
    public function get(Model $model, string $key, mixed $value, array $attributes): ?CarbonImmutable
    {
        if ($value === null || $value === '') {
            return null;
        }

        return CarbonImmutable::parse($value)->startOfDay();
    }

    public function set(Model $model, string $key, mixed $value, array $attributes): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }

        $date = $value instanceof DateTimeInterface
            ? CarbonImmutable::instance($value)
            : CarbonImmutable::parse($value);

        return $date->toDateString();
    }

    public function serialize(Model $model, string $key, mixed $value, array $attributes): ?string
    {
        return $value?->toDateString();
    }
}
