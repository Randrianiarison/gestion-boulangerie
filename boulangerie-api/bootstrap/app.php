<?php

use App\Http\Middleware\ForceJsonResponse;
use App\Http\Middleware\SetLocaleFromHeader;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Exceptions\ThrottleRequestsException;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        // Hébergement derrière un proxy (alwaysdata…) : HTTPS et IP du client lus dans les en-têtes X-Forwarded-*.
        $middleware->trustProxies(at: '*');

        $middleware->api(prepend: [
            ForceJsonResponse::class,
            SetLocaleFromHeader::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) {
        // Erreurs de l'API : toujours du JSON avec un `code` stable que l'appli traduit.
        $exceptions->shouldRenderJsonWhen(fn (Request $request) => $request->is('api/*') || $request->expectsJson());

        $error = function (string $code, int $status, Request $request) {
            SetLocaleFromHeader::apply($request);

            return response()->json(['message' => __('messages.errors.'.$code), 'code' => $code], $status);
        };

        $exceptions->render(fn (AuthenticationException $e, Request $request) => $request->is('api/*')
            ? $error('unauthenticated', 401, $request) : null);

        $exceptions->render(fn (AccessDeniedHttpException $e, Request $request) => $request->is('api/*')
            ? $error('forbidden', 403, $request) : null);

        $exceptions->render(fn (NotFoundHttpException $e, Request $request) => $request->is('api/*')
            ? $error('not_found', 404, $request) : null);

        $exceptions->render(fn (ThrottleRequestsException $e, Request $request) => $request->is('api/*')
            ? $error('too_many_attempts', 429, $request) : null);

        $exceptions->render(fn (ValidationException $e, Request $request) => $request->is('api/*')
            ? response()->json([
                'message' => $e->validator->errors()->first(),
                'code' => 'validation',
                'errors' => $e->errors(),
            ], 422)
            : null);
    })->create();
