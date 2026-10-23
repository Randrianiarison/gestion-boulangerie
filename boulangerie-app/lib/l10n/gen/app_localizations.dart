import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_fr.dart';
import 'app_localizations_mg.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('mg'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Boulangerie'**
  String get appTitle;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @languageMalagasy.
  ///
  /// In fr, this message translates to:
  /// **'Malagasy'**
  String get languageMalagasy;

  /// No description provided for @languageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @loginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get loginTitle;

  /// No description provided for @phoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get phoneLabel;

  /// No description provided for @pinLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN'**
  String get pinLabel;

  /// No description provided for @loginButton.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginButton;

  /// No description provided for @serverSettings.
  ///
  /// In fr, this message translates to:
  /// **'Adresse du serveur'**
  String get serverSettings;

  /// No description provided for @serverUrlLabel.
  ///
  /// In fr, this message translates to:
  /// **'Adresse de l\'API'**
  String get serverUrlLabel;

  /// No description provided for @serverUrlHelp.
  ///
  /// In fr, this message translates to:
  /// **'Émulateur Android : http://10.0.2.2:8000/api'**
  String get serverUrlHelp;

  /// No description provided for @greeting.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {name}'**
  String greeting(String name);

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In fr, this message translates to:
  /// **'Enregistré'**
  String get saved;

  /// No description provided for @paymentDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de paiement'**
  String get paymentDate;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get no;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get loading;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vous déconnecter ?'**
  String get logoutConfirm;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settings;

  /// No description provided for @connectedAs.
  ///
  /// In fr, this message translates to:
  /// **'Connecté : {name}'**
  String connectedAs(String name);

  /// No description provided for @roleOwner.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get roleOwner;

  /// No description provided for @roleStaff.
  ///
  /// In fr, this message translates to:
  /// **'Employé'**
  String get roleStaff;

  /// No description provided for @today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get yesterday;

  /// No description provided for @date.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @noData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée'**
  String get noData;

  /// No description provided for @errorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion au serveur. Vérifiez le Wi-Fi ou les données mobiles, puis réessayez.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur met trop de temps à répondre. Réessayez.'**
  String get errorTimeout;

  /// No description provided for @errorUnauthorized.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée : reconnectez-vous.'**
  String get errorUnauthorized;

  /// No description provided for @errorForbidden.
  ///
  /// In fr, this message translates to:
  /// **'Accès réservé au propriétaire.'**
  String get errorForbidden;

  /// No description provided for @errorNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Élément introuvable.'**
  String get errorNotFound;

  /// No description provided for @errorServer.
  ///
  /// In fr, this message translates to:
  /// **'Erreur du serveur. Réessayez plus tard.'**
  String get errorServer;

  /// No description provided for @errorTooManyAttempts.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Patientez une minute.'**
  String get errorTooManyAttempts;

  /// No description provided for @errorBadResponse.
  ///
  /// In fr, this message translates to:
  /// **'Réponse inattendue du serveur. Vérifiez l\'adresse du serveur dans les réglages.'**
  String get errorBadResponse;

  /// No description provided for @errorUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue.'**
  String get errorUnknown;

  /// No description provided for @homeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get homeTitle;

  /// No description provided for @revenueToday.
  ///
  /// In fr, this message translates to:
  /// **'Recettes du jour'**
  String get revenueToday;

  /// No description provided for @bread.
  ///
  /// In fr, this message translates to:
  /// **'Pain'**
  String get bread;

  /// No description provided for @juice.
  ///
  /// In fr, this message translates to:
  /// **'Jus'**
  String get juice;

  /// No description provided for @recovered.
  ///
  /// In fr, this message translates to:
  /// **'Invendus revendus'**
  String get recovered;

  /// No description provided for @alerts.
  ///
  /// In fr, this message translates to:
  /// **'Alertes'**
  String get alerts;

  /// No description provided for @noAlerts.
  ///
  /// In fr, this message translates to:
  /// **'Rien à signaler'**
  String get noAlerts;

  /// No description provided for @closingNotDone.
  ///
  /// In fr, this message translates to:
  /// **'Journée pas encore clôturée'**
  String get closingNotDone;

  /// No description provided for @closingDone.
  ///
  /// In fr, this message translates to:
  /// **'Journée clôturée'**
  String get closingDone;

  /// No description provided for @lowIngredients.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédients presque épuisés : {names}'**
  String lowIngredients(String names);

  /// No description provided for @billsDue.
  ///
  /// In fr, this message translates to:
  /// **'Factures à payer'**
  String get billsDue;

  /// No description provided for @salariesDue.
  ///
  /// In fr, this message translates to:
  /// **'Salaires dus'**
  String get salariesDue;

  /// No description provided for @stockToday.
  ///
  /// In fr, this message translates to:
  /// **'Stock du jour'**
  String get stockToday;

  /// No description provided for @menuProduction.
  ///
  /// In fr, this message translates to:
  /// **'Production'**
  String get menuProduction;

  /// No description provided for @menuSale.
  ///
  /// In fr, this message translates to:
  /// **'Vente'**
  String get menuSale;

  /// No description provided for @menuClosing.
  ///
  /// In fr, this message translates to:
  /// **'Clôture'**
  String get menuClosing;

  /// No description provided for @menuIngredients.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédients'**
  String get menuIngredients;

  /// No description provided for @menuExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses'**
  String get menuExpenses;

  /// No description provided for @menuEmployees.
  ///
  /// In fr, this message translates to:
  /// **'Employés'**
  String get menuEmployees;

  /// No description provided for @menuReports.
  ///
  /// In fr, this message translates to:
  /// **'Rapports'**
  String get menuReports;

  /// No description provided for @menuProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits'**
  String get menuProducts;

  /// No description provided for @menuUsers.
  ///
  /// In fr, this message translates to:
  /// **'Comptes'**
  String get menuUsers;

  /// No description provided for @formatPiece.
  ///
  /// In fr, this message translates to:
  /// **'pièce'**
  String get formatPiece;

  /// No description provided for @formatGlass.
  ///
  /// In fr, this message translates to:
  /// **'verre'**
  String get formatGlass;

  /// No description provided for @formatBottle.
  ///
  /// In fr, this message translates to:
  /// **'bouteille'**
  String get formatBottle;

  /// No description provided for @size.
  ///
  /// In fr, this message translates to:
  /// **'Taille'**
  String get size;

  /// No description provided for @sizeNone.
  ///
  /// In fr, this message translates to:
  /// **'Taille unique'**
  String get sizeNone;

  /// No description provided for @sizeSmall.
  ///
  /// In fr, this message translates to:
  /// **'Petit'**
  String get sizeSmall;

  /// No description provided for @sizeMedium.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get sizeMedium;

  /// No description provided for @sizeLarge.
  ///
  /// In fr, this message translates to:
  /// **'Grand'**
  String get sizeLarge;

  /// No description provided for @categoryBread.
  ///
  /// In fr, this message translates to:
  /// **'Pain'**
  String get categoryBread;

  /// No description provided for @categoryJuice.
  ///
  /// In fr, this message translates to:
  /// **'Jus'**
  String get categoryJuice;

  /// No description provided for @available.
  ///
  /// In fr, this message translates to:
  /// **'Dispo : {count}'**
  String available(String count);

  /// No description provided for @outOfStock.
  ///
  /// In fr, this message translates to:
  /// **'Épuisé'**
  String get outOfStock;

  /// No description provided for @price.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get price;

  /// No description provided for @quantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité'**
  String get quantity;

  /// No description provided for @quantityIn.
  ///
  /// In fr, this message translates to:
  /// **'Quantité ({unit})'**
  String quantityIn(String unit);

  /// No description provided for @productionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Production du matin'**
  String get productionTitle;

  /// No description provided for @productionAlreadyToday.
  ///
  /// In fr, this message translates to:
  /// **'Déjà enregistré aujourd\'hui'**
  String get productionAlreadyToday;

  /// No description provided for @productionSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer la production'**
  String get productionSave;

  /// No description provided for @productionConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer cette production ?'**
  String get productionConfirmTitle;

  /// No description provided for @productionSaved.
  ///
  /// In fr, this message translates to:
  /// **'Production enregistrée'**
  String get productionSaved;

  /// No description provided for @productionNothing.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez au moins une quantité'**
  String get productionNothing;

  /// No description provided for @deleteLotConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce lot : {quantity} × {product} ?'**
  String deleteLotConfirm(String quantity, String product);

  /// No description provided for @lotDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Lot supprimé'**
  String get lotDeleted;

  /// No description provided for @saleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vente'**
  String get saleTitle;

  /// No description provided for @saleTapToAdd.
  ///
  /// In fr, this message translates to:
  /// **'Touchez un produit pour l\'ajouter'**
  String get saleTapToAdd;

  /// No description provided for @saleValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider la vente'**
  String get saleValidate;

  /// No description provided for @saleConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Valider cette vente ?'**
  String get saleConfirmTitle;

  /// No description provided for @saleSaved.
  ///
  /// In fr, this message translates to:
  /// **'Vente enregistrée : {amount}'**
  String saleSaved(String amount);

  /// No description provided for @saleClear.
  ///
  /// In fr, this message translates to:
  /// **'Vider'**
  String get saleClear;

  /// No description provided for @closingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Clôture de la journée'**
  String get closingTitle;

  /// No description provided for @closingInstructions.
  ///
  /// In fr, this message translates to:
  /// **'Comptez ce qui reste pour chaque produit.'**
  String get closingInstructions;

  /// No description provided for @closingRemaining.
  ///
  /// In fr, this message translates to:
  /// **'Reste'**
  String get closingRemaining;

  /// No description provided for @closingSold.
  ///
  /// In fr, this message translates to:
  /// **'Vendu'**
  String get closingSold;

  /// No description provided for @closingUnsold.
  ///
  /// In fr, this message translates to:
  /// **'Invendu'**
  String get closingUnsold;

  /// No description provided for @closingRecovered.
  ///
  /// In fr, this message translates to:
  /// **'Montant récupéré (revendu moins cher)'**
  String get closingRecovered;

  /// No description provided for @closingNotCounted.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore compté'**
  String get closingNotCounted;

  /// No description provided for @closingCountAll.
  ///
  /// In fr, this message translates to:
  /// **'Comptez tous les produits pour valider'**
  String get closingCountAll;

  /// No description provided for @closingValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider la clôture'**
  String get closingValidate;

  /// No description provided for @closingConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Clôturer la journée du {date} ?'**
  String closingConfirmTitle(String date);

  /// No description provided for @closingConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Après validation, on ne peut plus vendre ni produire pour ce jour.'**
  String get closingConfirmBody;

  /// No description provided for @closingSaved.
  ///
  /// In fr, this message translates to:
  /// **'Journée clôturée'**
  String get closingSaved;

  /// No description provided for @closingAlreadyClosed.
  ///
  /// In fr, this message translates to:
  /// **'Journée déjà clôturée'**
  String get closingAlreadyClosed;

  /// No description provided for @closingSalesTotal.
  ///
  /// In fr, this message translates to:
  /// **'Ventes du jour'**
  String get closingSalesTotal;

  /// No description provided for @closingWasteTotal.
  ///
  /// In fr, this message translates to:
  /// **'Invendus'**
  String get closingWasteTotal;

  /// No description provided for @closingLostValue.
  ///
  /// In fr, this message translates to:
  /// **'Valeur perdue'**
  String get closingLostValue;

  /// No description provided for @closingCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la clôture'**
  String get closingCancel;

  /// No description provided for @closingCancelConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la clôture du {date} ? Les ventes et invendus calculés seront effacés pour recompter.'**
  String closingCancelConfirm(String date);

  /// No description provided for @closingCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Clôture annulée : vous pouvez recompter'**
  String get closingCancelled;

  /// No description provided for @closingNothingToCount.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit en stock ce jour-là.'**
  String get closingNothingToCount;

  /// No description provided for @closingBlockedFuture.
  ///
  /// In fr, this message translates to:
  /// **'On ne peut pas clôturer une date future.'**
  String get closingBlockedFuture;

  /// No description provided for @closingBlockedPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Une journée plus récente est déjà clôturée.'**
  String get closingBlockedPeriod;

  /// No description provided for @closingClosedBy.
  ///
  /// In fr, this message translates to:
  /// **'Clôturée par {name}'**
  String closingClosedBy(String name);

  /// No description provided for @closingAutomatic.
  ///
  /// In fr, this message translates to:
  /// **'Clôture automatique (sans comptage)'**
  String get closingAutomatic;

  /// No description provided for @expiringTonight.
  ///
  /// In fr, this message translates to:
  /// **'Expire ce soir : {count}'**
  String expiringTonight(String count);

  /// No description provided for @previousDay.
  ///
  /// In fr, this message translates to:
  /// **'Jour précédent'**
  String get previousDay;

  /// No description provided for @nextDay.
  ///
  /// In fr, this message translates to:
  /// **'Jour suivant'**
  String get nextDay;

  /// No description provided for @wasteDeclare.
  ///
  /// In fr, this message translates to:
  /// **'Déclarer un produit abîmé'**
  String get wasteDeclare;

  /// No description provided for @wasteDamaged.
  ///
  /// In fr, this message translates to:
  /// **'Abîmé'**
  String get wasteDamaged;

  /// No description provided for @wasteOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get wasteOther;

  /// No description provided for @wasteExpired.
  ///
  /// In fr, this message translates to:
  /// **'Périmé'**
  String get wasteExpired;

  /// No description provided for @wasteReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif'**
  String get wasteReason;

  /// No description provided for @wasteSaved.
  ///
  /// In fr, this message translates to:
  /// **'Invendu enregistré'**
  String get wasteSaved;

  /// No description provided for @ingredientsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédients'**
  String get ingredientsTitle;

  /// No description provided for @ingredientStock.
  ///
  /// In fr, this message translates to:
  /// **'Stock'**
  String get ingredientStock;

  /// No description provided for @ingredientThreshold.
  ///
  /// In fr, this message translates to:
  /// **'Seuil d\'alerte'**
  String get ingredientThreshold;

  /// No description provided for @ingredientLow.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt épuisé'**
  String get ingredientLow;

  /// No description provided for @ingredientPurchase.
  ///
  /// In fr, this message translates to:
  /// **'Achat'**
  String get ingredientPurchase;

  /// No description provided for @ingredientUsage.
  ///
  /// In fr, this message translates to:
  /// **'Utilisation'**
  String get ingredientUsage;

  /// No description provided for @ingredientPurchaseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Achat : {name}'**
  String ingredientPurchaseTitle(String name);

  /// No description provided for @ingredientUsageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Utilisation : {name}'**
  String ingredientUsageTitle(String name);

  /// No description provided for @totalPaid.
  ///
  /// In fr, this message translates to:
  /// **'Total payé'**
  String get totalPaid;

  /// No description provided for @unitPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix unitaire'**
  String get unitPrice;

  /// No description provided for @priceMode.
  ///
  /// In fr, this message translates to:
  /// **'Je connais…'**
  String get priceMode;

  /// No description provided for @supplier.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseur (facultatif)'**
  String get supplier;

  /// No description provided for @purchaseSaved.
  ///
  /// In fr, this message translates to:
  /// **'Achat enregistré'**
  String get purchaseSaved;

  /// No description provided for @usageSaved.
  ///
  /// In fr, this message translates to:
  /// **'Utilisation enregistrée'**
  String get usageSaved;

  /// No description provided for @purchases.
  ///
  /// In fr, this message translates to:
  /// **'Achats'**
  String get purchases;

  /// No description provided for @usages.
  ///
  /// In fr, this message translates to:
  /// **'Utilisations'**
  String get usages;

  /// No description provided for @ingredientNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel ingrédient'**
  String get ingredientNew;

  /// No description provided for @nameFr.
  ///
  /// In fr, this message translates to:
  /// **'Nom en français'**
  String get nameFr;

  /// No description provided for @nameMg.
  ///
  /// In fr, this message translates to:
  /// **'Nom en malgache'**
  String get nameMg;

  /// No description provided for @unit.
  ///
  /// In fr, this message translates to:
  /// **'Unité'**
  String get unit;

  /// No description provided for @unitKg.
  ///
  /// In fr, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @unitG.
  ///
  /// In fr, this message translates to:
  /// **'g'**
  String get unitG;

  /// No description provided for @unitL.
  ///
  /// In fr, this message translates to:
  /// **'litre'**
  String get unitL;

  /// No description provided for @unitPiece.
  ///
  /// In fr, this message translates to:
  /// **'pièce'**
  String get unitPiece;

  /// No description provided for @unitSachet.
  ///
  /// In fr, this message translates to:
  /// **'sachet'**
  String get unitSachet;

  /// No description provided for @expensesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses'**
  String get expensesTitle;

  /// No description provided for @expenseNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle dépense'**
  String get expenseNew;

  /// No description provided for @expenseCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get expenseCategory;

  /// No description provided for @catElectricity.
  ///
  /// In fr, this message translates to:
  /// **'Électricité'**
  String get catElectricity;

  /// No description provided for @catRent.
  ///
  /// In fr, this message translates to:
  /// **'Loyer'**
  String get catRent;

  /// No description provided for @catTransport.
  ///
  /// In fr, this message translates to:
  /// **'Transport'**
  String get catTransport;

  /// No description provided for @catPackaging.
  ///
  /// In fr, this message translates to:
  /// **'Emballages'**
  String get catPackaging;

  /// No description provided for @catOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get catOther;

  /// No description provided for @expenseLabel.
  ///
  /// In fr, this message translates to:
  /// **'Libellé'**
  String get expenseLabel;

  /// No description provided for @amount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get amount;

  /// No description provided for @expenseMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois concerné'**
  String get expenseMonth;

  /// No description provided for @dueDate.
  ///
  /// In fr, this message translates to:
  /// **'Date limite de paiement'**
  String get dueDate;

  /// No description provided for @alreadyPaid.
  ///
  /// In fr, this message translates to:
  /// **'Déjà payée'**
  String get alreadyPaid;

  /// No description provided for @paidOn.
  ///
  /// In fr, this message translates to:
  /// **'Payée le {date}'**
  String paidOn(String date);

  /// No description provided for @dueOn.
  ///
  /// In fr, this message translates to:
  /// **'À payer avant le {date}'**
  String dueOn(String date);

  /// No description provided for @statusPaid.
  ///
  /// In fr, this message translates to:
  /// **'Payée'**
  String get statusPaid;

  /// No description provided for @statusDue.
  ///
  /// In fr, this message translates to:
  /// **'À payer'**
  String get statusDue;

  /// No description provided for @statusOverdue.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get statusOverdue;

  /// No description provided for @markPaid.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme payée'**
  String get markPaid;

  /// No description provided for @markPaidConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Marquer « {label} » comme payée aujourd\'hui ?'**
  String markPaidConfirm(String label);

  /// No description provided for @expenseSaved.
  ///
  /// In fr, this message translates to:
  /// **'Dépense enregistrée'**
  String get expenseSaved;

  /// No description provided for @deleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer « {label} » ?'**
  String deleteConfirm(String label);

  /// No description provided for @deleted.
  ///
  /// In fr, this message translates to:
  /// **'Supprimé'**
  String get deleted;

  /// No description provided for @monthTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total du mois'**
  String get monthTotal;

  /// No description provided for @unpaidTotal.
  ///
  /// In fr, this message translates to:
  /// **'Reste à payer'**
  String get unpaidTotal;

  /// No description provided for @noExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Aucune dépense ce mois-ci'**
  String get noExpenses;

  /// No description provided for @employeesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Employés'**
  String get employeesTitle;

  /// No description provided for @employeeNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel employé'**
  String get employeeNew;

  /// No description provided for @employeeName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get employeeName;

  /// No description provided for @employeePhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone (facultatif)'**
  String get employeePhone;

  /// No description provided for @employeeRole.
  ///
  /// In fr, this message translates to:
  /// **'Poste'**
  String get employeeRole;

  /// No description provided for @rolePreparation.
  ///
  /// In fr, this message translates to:
  /// **'Préparation'**
  String get rolePreparation;

  /// No description provided for @roleSales.
  ///
  /// In fr, this message translates to:
  /// **'Vente'**
  String get roleSales;

  /// No description provided for @roleDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get roleDelivery;

  /// No description provided for @roleOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get roleOther;

  /// No description provided for @hiredOn.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'embauche'**
  String get hiredOn;

  /// No description provided for @leftOn.
  ///
  /// In fr, this message translates to:
  /// **'Date de départ'**
  String get leftOn;

  /// No description provided for @monthlySalary.
  ///
  /// In fr, this message translates to:
  /// **'Salaire mensuel'**
  String get monthlySalary;

  /// No description provided for @balanceDue.
  ///
  /// In fr, this message translates to:
  /// **'Reste à payer'**
  String get balanceDue;

  /// No description provided for @advance.
  ///
  /// In fr, this message translates to:
  /// **'Avance'**
  String get advance;

  /// No description provided for @unpaidMonths.
  ///
  /// In fr, this message translates to:
  /// **'{months} mois non payé(s)'**
  String unpaidMonths(String months);

  /// No description provided for @upToDate.
  ///
  /// In fr, this message translates to:
  /// **'À jour'**
  String get upToDate;

  /// No description provided for @totalDue.
  ///
  /// In fr, this message translates to:
  /// **'Total dû aux employés'**
  String get totalDue;

  /// No description provided for @accrued.
  ///
  /// In fr, this message translates to:
  /// **'Salaire gagné'**
  String get accrued;

  /// No description provided for @paid.
  ///
  /// In fr, this message translates to:
  /// **'Déjà payé'**
  String get paid;

  /// No description provided for @currentSalary.
  ///
  /// In fr, this message translates to:
  /// **'Salaire actuel'**
  String get currentSalary;

  /// No description provided for @pay.
  ///
  /// In fr, this message translates to:
  /// **'Payer'**
  String get pay;

  /// No description provided for @payTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiement : {name}'**
  String payTitle(String name);

  /// No description provided for @paymentSaved.
  ///
  /// In fr, this message translates to:
  /// **'Paiement enregistré'**
  String get paymentSaved;

  /// No description provided for @note.
  ///
  /// In fr, this message translates to:
  /// **'Remarque (facultatif)'**
  String get note;

  /// No description provided for @changeSalary.
  ///
  /// In fr, this message translates to:
  /// **'Changer le salaire'**
  String get changeSalary;

  /// No description provided for @newSalary.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau salaire mensuel'**
  String get newSalary;

  /// No description provided for @effectiveFrom.
  ///
  /// In fr, this message translates to:
  /// **'À partir du'**
  String get effectiveFrom;

  /// No description provided for @salaryChanged.
  ///
  /// In fr, this message translates to:
  /// **'Salaire modifié'**
  String get salaryChanged;

  /// No description provided for @paymentHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique des paiements'**
  String get paymentHistory;

  /// No description provided for @salaryHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique des salaires'**
  String get salaryHistory;

  /// No description provided for @noPayments.
  ///
  /// In fr, this message translates to:
  /// **'Aucun paiement'**
  String get noPayments;

  /// No description provided for @leftCompany.
  ///
  /// In fr, this message translates to:
  /// **'Parti le {date}'**
  String leftCompany(String date);

  /// No description provided for @markLeft.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le départ'**
  String get markLeft;

  /// No description provided for @reportsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rapports'**
  String get reportsTitle;

  /// No description provided for @week.
  ///
  /// In fr, this message translates to:
  /// **'Semaine'**
  String get week;

  /// No description provided for @month.
  ///
  /// In fr, this message translates to:
  /// **'Mois'**
  String get month;

  /// No description provided for @weekLabel.
  ///
  /// In fr, this message translates to:
  /// **'Du {from} au {to}'**
  String weekLabel(String from, String to);

  /// No description provided for @previousPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Période précédente'**
  String get previousPeriod;

  /// No description provided for @nextPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Période suivante'**
  String get nextPeriod;

  /// No description provided for @profit.
  ///
  /// In fr, this message translates to:
  /// **'Bénéfice'**
  String get profit;

  /// No description provided for @loss.
  ///
  /// In fr, this message translates to:
  /// **'Perte'**
  String get loss;

  /// No description provided for @revenue.
  ///
  /// In fr, this message translates to:
  /// **'Recettes'**
  String get revenue;

  /// No description provided for @charges.
  ///
  /// In fr, this message translates to:
  /// **'Charges'**
  String get charges;

  /// No description provided for @ingredientsCharge.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédients'**
  String get ingredientsCharge;

  /// No description provided for @salaries.
  ///
  /// In fr, this message translates to:
  /// **'Salaires'**
  String get salaries;

  /// No description provided for @partialUntil.
  ///
  /// In fr, this message translates to:
  /// **'Période en cours : calculé jusqu\'au {date}'**
  String partialUntil(String date);

  /// No description provided for @topProducts.
  ///
  /// In fr, this message translates to:
  /// **'Meilleures ventes'**
  String get topProducts;

  /// No description provided for @unsold.
  ///
  /// In fr, this message translates to:
  /// **'Invendus'**
  String get unsold;

  /// No description provided for @unsoldValue.
  ///
  /// In fr, this message translates to:
  /// **'Valeur des invendus (non déduite)'**
  String get unsoldValue;

  /// No description provided for @revenueVsCharges.
  ///
  /// In fr, this message translates to:
  /// **'Recettes et charges par jour'**
  String get revenueVsCharges;

  /// No description provided for @productsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Produits'**
  String get productsTitle;

  /// No description provided for @productNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau produit'**
  String get productNew;

  /// No description provided for @category.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get category;

  /// No description provided for @format.
  ///
  /// In fr, this message translates to:
  /// **'Format'**
  String get format;

  /// No description provided for @shelfLife.
  ///
  /// In fr, this message translates to:
  /// **'Se conserve (jours)'**
  String get shelfLife;

  /// No description provided for @shelfLifeHelp.
  ///
  /// In fr, this message translates to:
  /// **'1 = à vendre le jour même'**
  String get shelfLifeHelp;

  /// No description provided for @active.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé'**
  String get inactive;

  /// No description provided for @productSaved.
  ///
  /// In fr, this message translates to:
  /// **'Produit enregistré'**
  String get productSaved;

  /// No description provided for @usersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comptes'**
  String get usersTitle;

  /// No description provided for @userNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau compte'**
  String get userNew;

  /// No description provided for @userRole.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get userRole;

  /// No description provided for @newPin.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau code PIN (facultatif)'**
  String get newPin;

  /// No description provided for @pinHelp.
  ///
  /// In fr, this message translates to:
  /// **'4 à 6 chiffres'**
  String get pinHelp;

  /// No description provided for @userSaved.
  ///
  /// In fr, this message translates to:
  /// **'Compte enregistré'**
  String get userSaved;

  /// No description provided for @fieldRequired.
  ///
  /// In fr, this message translates to:
  /// **'Obligatoire'**
  String get fieldRequired;

  /// No description provided for @invalidNumber.
  ///
  /// In fr, this message translates to:
  /// **'Nombre invalide'**
  String get invalidNumber;

  /// No description provided for @invalidPhone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro invalide (ex. 034 12 345 67)'**
  String get invalidPhone;

  /// No description provided for @invalidPin.
  ///
  /// In fr, this message translates to:
  /// **'4 à 6 chiffres'**
  String get invalidPin;

  /// No description provided for @offline.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get offline;

  /// No description provided for @pendingOps.
  ///
  /// In fr, this message translates to:
  /// **'{count} en attente d\'envoi'**
  String pendingOps(String count);

  /// No description provided for @rejectedOps.
  ///
  /// In fr, this message translates to:
  /// **'{count} refusée(s) par le serveur : à vérifier'**
  String rejectedOps(String count);

  /// No description provided for @saleQueued.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion : vente de {amount} gardée sur le téléphone, envoyée dès le retour du réseau.'**
  String saleQueued(String amount);

  /// No description provided for @productionQueued.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion : production gardée sur le téléphone, envoyée dès le retour du réseau.'**
  String get productionQueued;

  /// No description provided for @outboxTitle.
  ///
  /// In fr, this message translates to:
  /// **'En attente d\'envoi'**
  String get outboxTitle;

  /// No description provided for @outboxHint.
  ///
  /// In fr, this message translates to:
  /// **'Les ventes et la production faites sans connexion sont gardées ici, puis envoyées automatiquement dès que le serveur répond.'**
  String get outboxHint;

  /// No description provided for @outboxEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Tout est envoyé.'**
  String get outboxEmpty;

  /// No description provided for @outboxSendNow.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer maintenant'**
  String get outboxSendNow;

  /// No description provided for @outboxStillOffline.
  ///
  /// In fr, this message translates to:
  /// **'Toujours pas de connexion. Nouvel essai automatique dans quelques secondes.'**
  String get outboxStillOffline;

  /// No description provided for @outboxPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get outboxPending;

  /// No description provided for @outboxRejected.
  ///
  /// In fr, this message translates to:
  /// **'Refusée'**
  String get outboxRejected;

  /// No description provided for @outboxDiscardConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette opération ? Elle ne sera jamais envoyée.'**
  String get outboxDiscardConfirm;

  /// No description provided for @closingPendingOps.
  ///
  /// In fr, this message translates to:
  /// **'{count} opération(s) pas encore envoyée(s) : envoyez-les avant de clôturer, sinon le compte serait faux.'**
  String closingPendingOps(String count);

  /// No description provided for @logoutPendingOps.
  ///
  /// In fr, this message translates to:
  /// **'{count} opération(s) en attente seront envoyées à la prochaine connexion.'**
  String logoutPendingOps(String count);

  /// No description provided for @invalidUrl.
  ///
  /// In fr, this message translates to:
  /// **'Adresse invalide'**
  String get invalidUrl;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['fr', 'mg'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr':
      return AppLocalizationsFr();
    case 'mg':
      return AppLocalizationsMg();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
