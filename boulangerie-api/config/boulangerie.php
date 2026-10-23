<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Premier propriétaire en production
    |--------------------------------------------------------------------------
    |
    | `php artisan db:seed` en production crée ce seul compte, à la place des
    | comptes de démo dont les PIN sont publiés dans le README. Retirez
    | SEED_OWNER_PIN du .env une fois le seed fait.
    |
    */

    'seed_owner' => [
        'name' => env('SEED_OWNER_NAME', 'Propriétaire'),
        'phone' => env('SEED_OWNER_PHONE'),
        'pin' => env('SEED_OWNER_PIN'),
    ],

];
