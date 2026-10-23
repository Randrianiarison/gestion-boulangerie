# Gestion de la boulangerie familiale

| Dossier | Contenu |
|---|---|
| [`boulangerie-api/`](boulangerie-api/README.md) | API REST Laravel 12 (MySQL, Sanctum) : installation, comptes de démo, routes |
| [`boulangerie-app/`](boulangerie-app/README.md) | Appli Flutter bilingue malgache / français |
| [`docs/CONCEPTION.md`](docs/CONCEPTION.md) | Modèle de données, règles de calcul, exemples chiffrés du bénéfice |
| [`docs/DEPLOIEMENT.md`](docs/DEPLOIEMENT.md) | Mise en ligne gratuite : API sur alwaysdata, APK sur les Releases GitHub |

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

Connexion de démo, en local uniquement : 034 00 000 01, PIN 1234 (propriétaire). Ces comptes ne
sont jamais créés sur un serveur en production.

APK à installer sur les téléphones (remplacez l'adresse par celle du PC qui fait tourner l'API) :

```bash
cd boulangerie-app
flutter build apk --release --dart-define=API_URL=http://192.168.1.20:8000/api
```

Le détail est dans [`boulangerie-app/README.md`](boulangerie-app/README.md#générer-lapk-installation-sur-les-téléphones),
y compris la sauvegarde de la clé de signature, indispensable pour les mises à jour.
