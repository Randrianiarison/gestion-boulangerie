# Gestion de la boulangerie familiale

| Dossier | Contenu |
|---|---|
| [`boulangerie-api/`](boulangerie-api/README.md) | API REST Laravel 12 (MySQL, Sanctum) : installation, comptes de démo, routes |
| [`boulangerie-app/`](boulangerie-app/README.md) | Appli Flutter bilingue malgache / français |
| [`docs/CONCEPTION.md`](docs/CONCEPTION.md) | Modèle de données, règles de calcul, exemples chiffrés du bénéfice |

Démarrage rapide :

```bash
cd boulangerie-api
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000
```

Puis, dans un autre terminal :

```bash
cd boulangerie-app
flutter run
```

Connexion de démo : 034 00 000 01, PIN 1234 (propriétaire).
