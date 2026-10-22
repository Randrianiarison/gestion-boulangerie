<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/** Langue des messages d'erreur : Accept-Language mg ou fr (fr par défaut). */
class SetLocaleFromHeader
{
    public const SUPPORTED = ['fr', 'mg'];

    public function handle(Request $request, Closure $next): Response
    {
        self::apply($request);

        return $next($request);
    }

    /** Aussi appelée par le rendu des erreurs, qui peut survenir avant le middleware (route inconnue). */
    public static function apply(Request $request): void
    {
        $locale = $request->getPreferredLanguage(self::SUPPORTED);
        app()->setLocale(in_array($locale, self::SUPPORTED, true) ? $locale : config('app.fallback_locale'));
    }
}
