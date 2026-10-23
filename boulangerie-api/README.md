# Boulangerie — API

API REST Laravel 12 pour gérer la boulangerie familiale : production, ventes, clôture de journée,
invendus, ingrédients, salaires, dépenses et bénéfice. Montants en Ariary (entiers).
Elle est utilisée par l'appli Flutter `boulangerie-app`.

Les règles de calcul sont détaillées dans [`../docs/CONCEPTION.md`](../docs/CONCEPTION.md).

## Prérequis

- PHP 8.3 ou plus récent, avec les extensions `pdo_mysql`, `pdo_sqlite` (tests), `mbstring`, `openssl`
- Composer 2
- MySQL 8

## Installation

```bash
composer install
cp .env.example .env
php artisan key:generate
```

Créez la base de données :

```bash
mysql -u root -p -e "CREATE DATABASE boulangerie CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
```

Puis renseignez la connexion dans `.env` :

```dotenv
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=boulangerie
DB_USERNAME=root
DB_PASSWORD=votre_mot_de_passe

APP_LOCALE=fr
APP_TIMEZONE=Indian/Antananarivo
```

Créez les tables et les données de départ (comptes, produits, ingrédients) :

```bash
php artisan migrate --seed
```

Facultatif : trois semaines d'activité fictive pour essayer les rapports et le tableau de bord.

```bash
php artisan db:seed --class=DemoDataSeeder
```

## Lancer le serveur

```bash
php artisan serve --host=0.0.0.0 --port=8000
```

- Depuis l'émulateur Android, l'API est sur `http://10.0.2.2:8000/api`.
- Depuis un vrai téléphone sur le même Wi-Fi, utilisez l'adresse IP du PC : `http://192.168.x.x:8000/api`.
  `--host=0.0.0.0` est nécessaire pour que le téléphone puisse joindre le PC.

## Comptes de démonstration

Connexion par numéro de téléphone et code PIN :

| Rôle | Téléphone | PIN |
|---|---|---|
| Propriétaire (`owner`) | 034 00 000 01 | 1234 |
| Employé (`staff`) | 034 00 000 02 | 5678 |

Ces comptes existent **seulement hors production**. Avec `APP_ENV=production`, `db:seed` crée
uniquement le propriétaire défini par `SEED_OWNER_PHONE` et `SEED_OWNER_PIN` dans `.env`, et
refuse les données de démo. Le dépôt étant public, ces PIN sont connus de tous.

## Tests

```bash
php artisan test
```

Les tests tournent sur SQLite en mémoire (`phpunit.xml`), sans toucher à MySQL.
Ils couvrent les calculateurs (`tests/Unit`) et toutes les routes de l'API (`tests/Feature`).

## Commande de rattrapage

```bash
php artisan stock:close-day              # clôture la journée d'hier
php artisan stock:close-day 2026-10-21   # clôture une date précise
```

Elle sert à clôturer une journée oubliée, sans comptage du soir : aucune vente n'est déduite et les
lots expirés passent en invendus. Elle est idempotente : la relancer ne change rien. Elle n'est
pas planifiée automatiquement.

## Rôles

- `owner` : accès complet, dont salaires, dépenses, rapports, catalogue et comptes.
- `staff` : production, ventes, clôture, invendus, stock et mouvements d'ingrédients.
  Le tableau de bord du staff ne contient ni factures ni salaires dus.

L'accès est contrôlé par des policies (`app/Policies`) et la gate `view-reports`.

## Langue des messages

L'en-tête `Accept-Language: mg` ou `fr` choisit la langue des messages d'erreur (français par défaut).
Chaque erreur métier renvoie aussi un `code` stable :

```json
{
  "message": "Stock insuffisant pour Baguette : 3 disponible(s), 5 demandé(s). Enregistrez d'abord la production.",
  "code": "insufficient_stock",
  "params": { "product": "Baguette", "available": 3, "requested": 5 }
}
```

| Statut | `code` |
|---|---|
| 401 | `unauthenticated` |
| 403 | `forbidden`, `account_disabled` |
| 404 | `not_found`, `closing_not_found` |
| 409 | `lot_already_used`, `product_has_history`, `ingredient_has_history`, `employee_has_payments`, `last_salary_rate` |
| 422 | `validation` (avec `errors` par champ), `invalid_credentials`, `insufficient_stock`, `remaining_exceeds_available`, `closing_missing_products`, `recovered_without_waste`, `future_date`, `day_closed`, `period_closed`, `closing_not_latest`, `closing_has_later_operations`, `insufficient_ingredient`, `cannot_modify_self` |
| 429 | `too_many_attempts` (5 essais de connexion par minute et par numéro) |

Les traductions malgaches (`lang/mg`) sont à faire relire par un locuteur natif.

## Routes

Toutes sont préfixées par `/api`, échangent du JSON et demandent un jeton Sanctum
(`Authorization: Bearer …`), sauf `POST /login`.

| Méthode | Route | Rôle | Description |
|---|---|---|---|
| POST | `/login` | — | `{phone, pin}` → `{token, user}` |
| POST | `/logout` | tous | Révoque le jeton |
| GET | `/me` | tous | Utilisateur connecté |
| GET | `/dashboard` | tous | Recettes du jour, stock, invendus, alertes ; factures et salaires dus pour l'owner |
| GET | `/products` (`?active=1`) | tous | Catalogue |
| POST/PUT/DELETE | `/products/{id}` | owner | Gestion du catalogue |
| GET | `/stock` (`?date=`) | tous | Disponible par produit |
| GET | `/production` (`?date=`) | tous | Lots produits ce jour-là |
| POST | `/production` | tous | `{produced_on?, items:[{product_id, quantity}]}` → un lot par produit |
| DELETE | `/production/{lot}` | tous | Supprime un lot encore intact (erreur de saisie) |
| GET | `/sales?from=&to=` | tous | Ventes et totaux |
| POST | `/sales` | tous | Vente au comptoir `{sold_on?, items:[{product_id, quantity}]}` |
| GET | `/day-closing/{date}` | tous | Disponible à compter, ou résumé si déjà clôturée |
| POST | `/day-closing/{date}` | tous | `{items:[{product_id, remaining, recovered_amount?}]}` |
| DELETE | `/day-closing/{date}` | owner | Annule la dernière clôture pour recompter |
| GET/POST | `/waste-records` | tous | Invendus ; saisie manuelle `damaged` ou `other` |
| PATCH | `/waste-records/{id}` | tous | Montant récupéré renseigné après coup |
| GET | `/ingredients/stock` | tous | Stock des ingrédients, alertes en premier |
| GET | `/ingredients`, `/ingredients/{id}` | tous | Liste ; fiche avec historique |
| POST/PUT/DELETE | `/ingredients/{id}` | owner | Gestion des ingrédients |
| GET/POST | `/ingredient-purchases` | tous | Achat : quantité + prix unitaire **ou** total payé |
| GET/POST | `/ingredient-usages` | tous | Utilisation (refusée au-delà du stock) |
| DELETE | `/ingredient-purchases/{id}`, `/ingredient-usages/{id}` | owner | Corrections |
| CRUD | `/employees` | owner | Création avec `monthly_amount` (salaire en vigueur dès l'embauche) |
| GET | `/employees/{id}/balance` | owner | Acquis, payé, solde dû, mois non payés |
| GET/POST | `/employees/{id}/salary-rates` | owner | Historique / changement de salaire à une date |
| DELETE | `/salary-rates/{id}` | owner | |
| GET/POST | `/employees/{id}/payments` | owner | Paiements (un mois, plusieurs mois, avance) |
| DELETE | `/salary-payments/{id}` | owner | |
| CRUD | `/expenses` (`?month=&status=&category=`) | owner | Dépenses ; `period_month` obligatoire pour l'électricité et le loyer |
| POST | `/expenses/{id}/pay` | owner | Marque une facture comme payée |
| GET | `/reports/summary?period=week\|month&date=` | owner | Bénéfice, détail des charges, top produits, série par jour |
| GET/POST/PUT | `/users` | owner | Comptes de connexion (PIN, rôle, désactivation) |

## Organisation du code

- `app/Services/SalaryCalculator.php` : salaire acquis jour par jour, solde dû, mois non payés.
- `app/Services/ProfitCalculator.php` : recettes, charges et bénéfice d'une semaine ou d'un mois.
- `app/Services/StockService.php` : lots, disponible, consommation FIFO.
- `app/Services/DayClosingService.php` : clôture, invendus, annulation.
- `app/Services/DayLock.php` : une journée clôturée est figée.
- `app/Http/Requests` : validation (Form Requests) ; `app/Http/Resources` : format JSON.
- `app/Casts/DateOnly.php` : dates stockées en `AAAA-MM-JJ` en MySQL comme en SQLite.

## Mise en production

Le guide pas à pas pour un hébergement gratuit sur alwaysdata est dans
[`../docs/DEPLOIEMENT.md`](../docs/DEPLOIEMENT.md). Il couvre la base de données, le SSH,
l'installation et le HTTPS.

- Modèle de configuration : `.env.alwaysdata.example`, avec `APP_ENV=production` et `APP_DEBUG=false`.
- Mises à jour : `bash deploy.sh` sur le serveur. Le script récupère le code, installe les
  dépendances, applique les migrations et remet les caches à jour.
- L'API fait confiance aux en-têtes du proxy (`trustProxies`) : derrière l'hébergeur, elle voit bien
  les requêtes HTTPS.
- Servez toujours l'API en HTTPS hors du réseau local : le jeton circule dans chaque requête.
- Sauvegardez la base régulièrement (`mysqldump`, voir le guide).
