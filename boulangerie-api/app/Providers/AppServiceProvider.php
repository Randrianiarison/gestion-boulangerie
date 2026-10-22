<?php

namespace App\Providers;

use App\Models\User;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Rapports (bénéfice, charges) : owner uniquement.
        Gate::define('view-reports', fn (User $user) => $user->isOwner());

        // Un code PIN de 4 chiffres se devine vite : 5 essais par minute et par numéro.
        RateLimiter::for('login', fn (Request $request) => Limit::perMinute(5)
            ->by($request->input('phone').'|'.$request->ip()));
    }
}
