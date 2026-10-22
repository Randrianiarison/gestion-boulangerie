# Boulangerie — appli mobile

Appli Flutter bilingue (malgache / français) pour la boulangerie familiale, branchée sur l'API
`boulangerie-api`. Elle est pensée pour des utilisateurs peu habitués au numérique : gros boutons,
peu de texte, montants « 12 500 Ar » et confirmation avant chaque validation.

## Prérequis

- Flutter 3 stable (testé avec 3.41, Dart 3.11)
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
```

## Réseau

- Android : `usesCleartextTraffic="true"` et la permission `INTERNET` autorisent l'appel HTTP vers
  le PC sur le réseau local.
- iOS : `NSAllowsArbitraryLoads` dans `Info.plist`, pour la même raison.
- Si l'API est un jour exposée sur Internet, passez-la en HTTPS et retirez ces exceptions.
