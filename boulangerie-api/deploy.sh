#!/usr/bin/env bash
# Met l'API en ligne à jour depuis GitHub. À lancer en SSH sur le serveur :
#   bash ~/gestion-boulangerie/boulangerie-api/deploy.sh
set -euo pipefail

cd "$(dirname "$0")"

php artisan down --retry=15 || true
trap 'php artisan up' EXIT

git pull --ff-only
composer install --no-dev --optimize-autoloader --no-interaction
php artisan migrate --force
php artisan optimize

echo "API à jour : $(git log -1 --format='%h %s')"
