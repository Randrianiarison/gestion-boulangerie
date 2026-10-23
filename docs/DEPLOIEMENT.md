# Mise en ligne gratuite

| Quoi | Où | Coût |
|---|---|---|
| L'API (le serveur) | [alwaysdata](https://www.alwaysdata.com), offre gratuite | 0 € |
| L'APK (l'appli Android) | Releases GitHub du dépôt public | 0 € |

Avec cette configuration, l'appli fonctionne partout où il y a Internet, et plus seulement sur le
Wi-Fi de la boutique.

---

## Partie 1 : l'API sur alwaysdata

L'offre gratuite d'alwaysdata est gratuite à vie : 1 Go de disque, 256 Mo de mémoire, un quart de
processeur et 3 jours de sauvegardes. C'est largement suffisant pour une boulangerie.

Elle est prévue « pour des besoins personnels ». Si l'appli devient indispensable au commerce, une
petite offre payante sera plus sûre. La procédure ci-dessous reste la même.

Dans les étapes suivantes, remplacez **COMPTE** par le nom de votre compte alwaysdata.

### 1. Créer le compte

1. Sur [alwaysdata.com](https://www.alwaysdata.com), inscrivez-vous et choisissez l'offre **gratuite**.
2. Choisissez le nom du compte avec soin, par exemple `boulangerie-rakoto` : l'adresse de l'API
   sera `https://COMPTE.alwaysdata.net`.

### 2. Choisir la version de PHP

Dans l'administration, menu **Environnement → PHP** : choisissez **8.4**, la version utilisée pour
le développement (8.3 convient aussi).

### 3. Créer la base de données

1. Menu **Bases de données → MySQL**.
2. Ajoutez une base nommée `COMPTE_boulangerie`.
3. Dans l'onglet **Utilisateurs**, notez le nom de l'utilisateur MySQL (en général le nom du
   compte), choisissez son mot de passe et donnez-lui accès à cette base.

### 4. Activer l'accès SSH

1. Menu **Accès distant → SSH**, modifiez l'utilisateur et cochez la connexion par mot de passe.
   SSH est désactivé par défaut.
2. Depuis le PC, connectez-vous :

```bash
ssh COMPTE@ssh-COMPTE.alwaysdata.net
```

Le même menu propose aussi un terminal dans le navigateur, mais il est plus lent.

### 5. Installer l'API (dans le terminal SSH)

```bash
git clone https://github.com/Randrianiarison/gestion-boulangerie.git
cd gestion-boulangerie/boulangerie-api
composer install --no-dev --optimize-autoloader --no-interaction
cp .env.alwaysdata.example .env
nano .env
```

Si la commande `composer` est introuvable, installez-le d'abord avec
`curl -sS https://getcomposer.org/installer | php`, puis utilisez `php composer.phar install …`.

Dans `.env`, remplacez chaque `COMPTE` et remplissez :

- `DB_PASSWORD` : le mot de passe MySQL choisi à l'étape 3 ;
- `SEED_OWNER_PHONE` et `SEED_OWNER_PIN` : le téléphone et le code PIN du **vrai** propriétaire
  (4 à 6 chiffres, pas 1234).

Enregistrez avec `Ctrl+O`, puis quittez avec `Ctrl+X`. Ensuite :

```bash
php artisan key:generate --force
php artisan migrate --force
php artisan db:seed --force
sed -i '/^SEED_OWNER_PIN=/d' .env
php artisan optimize
```

En production, `db:seed` crée **seulement** ce propriétaire, plus le catalogue et les ingrédients
de départ. Les comptes de démo (034 00 000 01 / 1234), dont les PIN sont publiés dans le README,
ne sont jamais créés en ligne, et les données fictives sont refusées. La commande `sed` retire
ensuite le PIN du fichier `.env`. Les employés se créent ensuite dans l'appli (écran **Comptes**).

### 6. Brancher le site sur l'API

1. Menu **Web → Sites**, modifiez le site `COMPTE.alwaysdata.net`.
2. Type : **PHP**.
3. Répertoire racine : `/gestion-boulangerie/boulangerie-api/public`.
4. Enregistrez. L'adresse `https://COMPTE.alwaysdata.net` fonctionne en HTTPS.

### 7. Vérifier

- Ouvrez `https://COMPTE.alwaysdata.net/up` dans un navigateur : la page doit indiquer que
  l'application tourne.
- Testez la connexion du propriétaire depuis le PC :

```bash
curl -X POST https://COMPTE.alwaysdata.net/api/login -H "Content-Type: application/json" -d "{\"phone\":\"034 12 345 67\",\"pin\":\"VOTRE_PIN\"}"
```

La réponse doit contenir un `token`.

### Mettre à jour l'API plus tard

Après un `git push` depuis le PC, lancez en SSH :

```bash
bash ~/gestion-boulangerie/boulangerie-api/deploy.sh
```

Le script met l'API en maintenance quelques secondes, puis :
1. récupère le code ;
2. installe les dépendances ;
3. applique les migrations ;
4. remet l'API en ligne.

### Sauvegardes

alwaysdata garde 3 jours de sauvegardes. Pour en garder plus, exportez la base chaque semaine,
depuis phpMyAdmin ou en SSH :

```bash
mysqldump -h mysql-COMPTE.alwaysdata.net -u COMPTE -p COMPTE_boulangerie > sauvegarde-$(date +%F).sql
```

Rapatriez ensuite le fichier sur le PC, avec `scp` ou par le menu **Fichiers**.

---

## Partie 2 : l'APK sur GitHub (Releases)

Le dépôt est public : GitHub héberge gratuitement les fichiers APK attachés à une « release ».

### 1. Construire l'APK avec l'adresse du serveur

Sur le PC :

```bash
cd boulangerie-app
flutter build apk --release --dart-define=API_URL=https://COMPTE.alwaysdata.net/api
```

Le fichier est produit ici : `boulangerie-app/build/app/outputs/flutter-apk/app-release.apk`.

### 2. Publier la release

1. Sur GitHub, ouvrez le dépôt, puis **Releases → Draft a new release**.
2. Tag : `v1.0.0` (même numéro que `version:` dans `pubspec.yaml`), titre : `Boulangerie 1.0.0`.
3. Glissez `app-release.apk` dans la zone des fichiers joints.
4. Cliquez **Publish release**.

### 3. Partager le lien

Ce lien télécharge toujours la **dernière** version, à condition de garder le nom de fichier
`app-release.apk` :

```
https://github.com/Randrianiarison/gestion-boulangerie/releases/latest/download/app-release.apk
```

Envoyez-le par WhatsApp ou SMS, ou affichez-le en QR code à la boutique. Sur le téléphone, ouvrez
le fichier téléchargé et acceptez « Installer des applis de sources inconnues ».

N'importe qui peut télécharger l'APK, mais sans compte (téléphone + PIN créé par le propriétaire),
on ne voit aucune donnée.

### Publier une nouvelle version

1. Augmentez `version:` dans `pubspec.yaml` : `1.0.0+1` → `1.0.1+2`.
2. Reconstruisez l'APK (étape 1).
3. Publiez une nouvelle release `v1.0.1` avec le même nom de fichier.

Le lien ne change pas. Les téléphones installent la nouvelle version par-dessus l'ancienne, à
condition qu'elle soit signée avec la même clé (voir `boulangerie-app/README.md`).

---

## Sécurité en ligne

- **HTTPS :** l'adresse `*.alwaysdata.net` est servie en HTTPS. Le jeton de connexion ne circule
  donc pas en clair.
- **Comptes de démo :** jamais créés en production.
- **Code PIN :** 5 essais par minute et par numéro au maximum. Choisissez des PIN à 6 chiffres
  pour le propriétaire.
- **Secrets :** le `.env` du serveur (mot de passe MySQL, `APP_KEY`) reste sur le serveur. Il est
  ignoré par git et ne doit jamais être copié dans le dépôt public.
