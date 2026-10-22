<?php

namespace App\Exceptions;

use Illuminate\Http\JsonResponse;
use RuntimeException;

/**
 * Règle métier violée (stock insuffisant, journée clôturée…).
 *
 * Rendue en JSON avec un `code` stable que l'appli traduit elle-même,
 * plus un `message` déjà traduit dans la langue de la requête.
 */
class BusinessRuleException extends RuntimeException
{
    /**
     * @param  array<string, scalar>  $params
     */
    public function __construct(
        public readonly string $errorCode,
        public readonly array $params = [],
        public readonly int $status = 422,
    ) {
        parent::__construct(__('messages.errors.'.$errorCode, self::humanDates($params)));
    }

    /**
     * Dates ISO affichées en jj/mm/aaaa dans le message ; `params` les garde en ISO pour l'appli.
     *
     * @param  array<string, scalar>  $params
     * @return array<string, scalar>
     */
    private static function humanDates(array $params): array
    {
        return array_map(
            fn ($value) => is_string($value) && preg_match('/^(\d{4})-(\d{2})-(\d{2})$/', $value, $m)
                ? "{$m[3]}/{$m[2]}/{$m[1]}"
                : $value,
            $params,
        );
    }

    public function render(): JsonResponse
    {
        return response()->json([
            'message' => $this->getMessage(),
            'code' => $this->errorCode,
            'params' => (object) $this->params,
        ], $this->status);
    }
}
