<?php

namespace App\Http\Middleware;

use App\Models\IdempotencyKey;
use Closure;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * En-tête « Idempotency-Key » : l'appli renvoie une vente faite hors ligne tant qu'elle n'a pas
 * reçu de réponse. Si la première tentative a abouti (réponse perdue en route), on rejoue la
 * même réponse au lieu d'enregistrer la vente une deuxième fois.
 *
 * Seules les réussites (2xx) sont mémorisées : une vente refusée (stock épuisé…) peut être
 * renvoyée plus tard avec la même clé, une fois le problème réglé.
 */
class Idempotent
{
    private const KEY_PATTERN = '/^[A-Za-z0-9-]{8,64}$/';

    public function handle(Request $request, Closure $next): Response
    {
        $key = $request->header('Idempotency-Key');
        $user = $request->user();

        if ($user === null || ! is_string($key) || ! preg_match(self::KEY_PATTERN, $key)) {
            return $next($request);
        }

        $previous = IdempotencyKey::where('user_id', $user->id)->where('key', $key)->first();
        if ($previous !== null) {
            return response($previous->response, $previous->status_code, [
                'Content-Type' => 'application/json',
                'Idempotent-Replayed' => 'true',
            ]);
        }

        $response = $next($request);

        if ($response->isSuccessful()) {
            try {
                IdempotencyKey::create([
                    'user_id' => $user->id,
                    'key' => $key,
                    'status_code' => $response->getStatusCode(),
                    'response' => (string) $response->getContent(),
                ]);
            } catch (UniqueConstraintViolationException) {
                // Deux envois simultanés de la même opération : la première réponse est déjà gardée.
            }
        }

        return $response;
    }
}
