# Boulangerie — appli mobile

Appli Flutter bilingue (malgache / français) pour la boulangerie familiale, branchée sur l'API
`boulangerie-api`. Elle est pensée pour des utilisateurs peu habitués au numérique : gros boutons,
peu de texte, montants « 12 500 Ar » et confirmation avant chaque validation.

## Prérequis

- Flutter 3 stable (testé avec 3.41, Dart 3.11)
- Pour construire l'APK : Android Studio, qui fournit le SDK Android et Java. Les licences du SDK
  doivent être acceptées une fois : `flutter doctor --android-licenses`.
- L'API qui tourne (voir `../boulangerie-api/README.md`) :

  ```bash
  php artisan serve --host=0.0.0.0 --port=8000
  ```

## Lancer l'appli

```bash
flutter pub get
flutter run
```

Par défaut, l'appli appelle `http://10.0.2.2:8000/api`, l'adresse de la machine hôte vue depuis
l'émulateur Android.

Sur un vrai téléphone, sur le même Wi-Fi que le PC qui fait tourner l'API :

```bash
flutter run --dart-define=API_URL=http://192.168.1.20:8000/api
```

Vous pouvez aussi changer l'adresse dans l'appli, sans recompiler : icône serveur en haut de l'écran
de connexion, ou Réglages → Adresse du serveur. Elle est mémorisée sur le téléphone.

Comptes de démonstration (créés par `php artisan migrate --seed`) :

| Rôle | Téléphone | PIN |
|---|---|---|
| Propriétaire | 034 00 000 01 | 1234 |
| Employé | 034 00 000 02 | 5678 |

## Générer l'APK (installation sur les téléphones)

Si l'API est hébergée en ligne (gratuitement sur alwaysdata, voir
[`../docs/DEPLOIEMENT.md`](../docs/DEPLOIEMENT.md)), construisez l'APK avec son adresse HTTPS :
`--dart-define=API_URL=https://COMPTE.alwaysdata.net/api`. Publiez-le ensuite sur les Releases
GitHub : le lien de téléchargement est gratuit et ne change pas d'une version à l'autre.

Les étapes ci-dessous concernent le cas où l'API tourne sur le PC de la boutique.

### 1. Trouver l'adresse du PC qui fait tourner l'API

Sur ce PC, `ipconfig` donne l'« Adresse IPv4 » sur le Wi-Fi, par exemple `192.168.1.20`.
Fixez cette adresse dans la box (bail DHCP réservé), sinon elle peut changer et l'appli ne trouvera
plus le serveur.

### 2. Construire l'APK

```bash
flutter build apk --release --dart-define=API_URL=http://192.168.1.20:8000/api
```

Le fichier est créé ici : `build/app/outputs/flutter-apk/app-release.apk`. Cet APK unique (environ
54 Mo) fonctionne sur tous les téléphones Android 7 ou plus récents.

Le tout premier build prend environ un quart d'heure, le temps que Gradle télécharge ses outils.
Les suivants sont beaucoup plus rapides.

L'adresse est gravée dans l'APK : les téléphones n'ont rien à régler. Si elle change, on peut
toujours la corriger dans l'appli (icône serveur sur l'écran de connexion), sans recompiler.

Pour un fichier plus léger, `--split-per-abi` crée un APK par type de processeur. Installez alors
`app-arm64-v8a-release.apk`, qui convient à la quasi-totalité des téléphones récents.

### 3. Installer sur un téléphone

- Envoyez `app-release.apk` sur le téléphone (câble USB, clé USB, Bluetooth, WhatsApp…), ouvrez-le,
  puis acceptez « Installer des applis de sources inconnues » quand Android le demande.
- Ou, téléphone branché en USB avec le mode développeur activé :

  ```bash
  flutter install --release
  ```

### 4. Publier une mise à jour

1. Augmentez la version dans `pubspec.yaml`. Le nombre après `+` doit **toujours augmenter** :
   `1.0.0+1` → `1.0.1+2`.
2. Reconstruisez l'APK (étape 2) et installez-le par-dessus l'ancien. Les données ne bougent pas :
   elles sont sur le serveur.

### Clé de signature : à sauvegarder absolument

Android n'accepte une mise à jour que si elle est signée avec **la même clé** que l'appli installée.
Sur ce PC, la clé existe déjà :

- `C:\Users\JOHNS\.keystores\boulangerie-upload.jks` : la clé ;
- `android/key.properties` : son mot de passe et son emplacement.

Aucun des deux n'est dans git. Copiez-les ensemble dans un endroit sûr (clé USB, gestionnaire de mots
de passe). Sans eux, il faudra désinstaller l'appli de chaque téléphone avant d'installer la nouvelle
version. Rien n'est perdu côté serveur, mais il faut se reconnecter.

Sur un autre PC, recopiez ces deux fichiers et corrigez `storeFile` dans `android/key.properties`.
Pour repartir d'une nouvelle clé :

```bash
keytool -genkeypair -keystore boulangerie-upload.jks -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Ensuite, remplissez `android/key.properties` d'après `android/key.properties.example`.

`keytool` est fourni avec Android Studio : `C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe`.
Sans `key.properties`, la compilation n'échoue pas : elle signe avec la clé de debug et affiche un
avertissement. Un tel APK ne peut pas mettre à jour une appli installée avec la vraie clé.

### Nom et icône

- **Nom sous l'icône :**
  - Android : `android/app/src/main/res/values/strings.xml` (`app_name`) ;
  - iOS : `ios/Runner/Info.plist` (`CFBundleDisplayName`).
- **Icône :** un croissant blanc sur la couleur du thème, dessiné par `tool/generate_app_icon.dart`.
  Pour la changer, modifiez ce fichier, puis :

  ```bash
  flutter test tool/generate_app_icon.dart
  dart run flutter_launcher_icons
  ```

## Vérifications

```bash
flutter analyze
flutter test
```

Les tests couvrent :

- le formatage (Ariary, dates en malgache) et la lecture du JSON de l'API ;
- la traduction des erreurs ;
- la présence des mêmes clés dans les deux fichiers ARB ;
- le passage en malgache sans plantage ;
- un parcours de **tous les écrans** à la taille d'un téléphone (360 × 800), en malgache et en
  français, avec des données factices (aucun débordement de texte) ;
- le panier de vente et la clôture.

## Écrans

| Écran | Qui | Rôle |
|---|---|---|
| Connexion | tous | Téléphone + code PIN, choix de la langue |
| Accueil | tous | Recettes du jour, alertes (clôture à faire, ingrédients, factures, salaires dus), accès rapides, stock |
| Production | tous | Quantité par produit avec boutons − / +, une seule validation |
| Vente | tous | Grosses tuiles produits ; toucher = +1, total, validation |
| Clôture | tous | Reste compté par produit, aperçu vendu / invendus, validation ; l'owner peut annuler la dernière clôture |
| Ingrédients | tous | Stock, alertes, achat (total payé ou prix unitaire), utilisation ; l'owner gère la liste |
| Dépenses | owner | Mois par mois, factures payées / à payer / en retard |
| Employés | owner | Solde dû, mois non payés, paiements, changements de salaire |
| Rapports | owner | Semaine / mois, période précédente / suivante, graphique recettes vs charges, détail, bénéfice |
| Produits, Comptes | owner | Catalogue et prix ; comptes de connexion et codes PIN |

## Langues

- Les textes sont dans `lib/l10n/app_mg.arb` et `lib/l10n/app_fr.arb`. Le code Dart est généré dans
  `lib/l10n/gen` par `flutter gen-l10n`, qui tourne aussi automatiquement avec `flutter run`.
- Le malgache est la langue par défaut. Le choix est mémorisé sur le téléphone.
- `flutter_localizations` ne fournit pas de traductions Material pour `mg`. Sans délégué pour cette
  langue, `MaterialApp` plante dès qu'on passe en malgache. `lib/l10n/fallback_localizations.dart`
  charge donc les traductions françaises de Material, Cupertino et Widgets quand l'appli est en
  malgache : les boutons du calendrier s'affichent en français, tout le reste en malgache.
- Le paquet `intl` ne connaît pas non plus le malgache. Les noms de mois et de jours sont dans
  `lib/core/format.dart` (`DateLabels`).
- Les messages d'erreur métier viennent de l'API, déjà traduits grâce à l'en-tête `Accept-Language`.
  Les erreurs réseau (pas de connexion, délai dépassé, mauvaise adresse) sont traduites par l'appli.
- Les traductions malgaches sont à faire relire par un locuteur natif.

## Organisation du code

```
lib/
  main.dart, app.dart, router.dart   démarrage, thème, langues, routes et accès owner
  core/        client HTTP (Dio), erreurs, formats, thème, réglages mémorisés
  data/        appels typés à l'API (BakeryApi) et providers Riverpod
  models/      objets lus depuis le JSON de l'API
  features/    un dossier par écran
  widgets/     composants partagés (stepper − / +, confirmations, champs, cartes)
  l10n/        fichiers ARB et délégués de repli pour le malgache
test/          tests unitaires et widgets, dont le parcours de tous les écrans
tool/          generate_app_icon.dart (dessin de l'icône)
assets/icon/   images sources de l'icône
```

## Réseau

- Android : `usesCleartextTraffic="true"` et la permission `INTERNET` autorisent l'appel HTTP vers
  le PC sur le réseau local.
- iOS : `NSAllowsArbitraryLoads` dans `Info.plist`, pour la même raison.
- Si l'API est un jour exposée sur Internet, passez-la en HTTPS et retirez ces exceptions.
