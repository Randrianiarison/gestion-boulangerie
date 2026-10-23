// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Boulangerie';

  @override
  String get language => 'Langue';

  @override
  String get languageMalagasy => 'Malagasy';

  @override
  String get languageFrench => 'Français';

  @override
  String get loginTitle => 'Connexion';

  @override
  String get phoneLabel => 'Numéro de téléphone';

  @override
  String get pinLabel => 'Code PIN';

  @override
  String get loginButton => 'Se connecter';

  @override
  String get serverSettings => 'Adresse du serveur';

  @override
  String get serverUrlLabel => 'Adresse de l\'API';

  @override
  String get serverUrlHelp => 'Émulateur Android : http://10.0.2.2:8000/api';

  @override
  String greeting(String name) {
    return 'Bonjour $name';
  }

  @override
  String get save => 'Enregistrer';

  @override
  String get saved => 'Enregistré';

  @override
  String get paymentDate => 'Date de paiement';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get close => 'Fermer';

  @override
  String get retry => 'Réessayer';

  @override
  String get edit => 'Modifier';

  @override
  String get delete => 'Supprimer';

  @override
  String get add => 'Ajouter';

  @override
  String get loading => 'Chargement…';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get logoutConfirm => 'Voulez-vous vous déconnecter ?';

  @override
  String get settings => 'Réglages';

  @override
  String connectedAs(String name) {
    return 'Connecté : $name';
  }

  @override
  String get roleOwner => 'Propriétaire';

  @override
  String get roleStaff => 'Employé';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get date => 'Date';

  @override
  String get total => 'Total';

  @override
  String get noData => 'Aucune donnée';

  @override
  String get errorNetwork =>
      'Pas de connexion au serveur. Vérifiez le Wi-Fi ou les données mobiles, puis réessayez.';

  @override
  String get errorTimeout =>
      'Le serveur met trop de temps à répondre. Réessayez.';

  @override
  String get errorUnauthorized => 'Session expirée : reconnectez-vous.';

  @override
  String get errorForbidden => 'Accès réservé au propriétaire.';

  @override
  String get errorNotFound => 'Élément introuvable.';

  @override
  String get errorServer => 'Erreur du serveur. Réessayez plus tard.';

  @override
  String get errorTooManyAttempts =>
      'Trop de tentatives. Patientez une minute.';

  @override
  String get errorBadResponse =>
      'Réponse inattendue du serveur. Vérifiez l\'adresse du serveur dans les réglages.';

  @override
  String get errorUnknown => 'Une erreur est survenue.';

  @override
  String get homeTitle => 'Accueil';

  @override
  String get revenueToday => 'Recettes du jour';

  @override
  String get bread => 'Pain';

  @override
  String get juice => 'Jus';

  @override
  String get recovered => 'Invendus revendus';

  @override
  String get alerts => 'Alertes';

  @override
  String get noAlerts => 'Rien à signaler';

  @override
  String get closingNotDone => 'Journée pas encore clôturée';

  @override
  String get closingDone => 'Journée clôturée';

  @override
  String lowIngredients(String names) {
    return 'Ingrédients presque épuisés : $names';
  }

  @override
  String get billsDue => 'Factures à payer';

  @override
  String get salariesDue => 'Salaires dus';

  @override
  String get stockToday => 'Stock du jour';

  @override
  String get menuProduction => 'Production';

  @override
  String get menuSale => 'Vente';

  @override
  String get menuClosing => 'Clôture';

  @override
  String get menuIngredients => 'Ingrédients';

  @override
  String get menuExpenses => 'Dépenses';

  @override
  String get menuEmployees => 'Employés';

  @override
  String get menuReports => 'Rapports';

  @override
  String get menuProducts => 'Produits';

  @override
  String get menuUsers => 'Comptes';

  @override
  String get formatPiece => 'pièce';

  @override
  String get formatGlass => 'verre';

  @override
  String get formatBottle => 'bouteille';

  @override
  String get size => 'Taille';

  @override
  String get sizeNone => 'Taille unique';

  @override
  String get sizeSmall => 'Petit';

  @override
  String get sizeMedium => 'Moyen';

  @override
  String get sizeLarge => 'Grand';

  @override
  String get categoryBread => 'Pain';

  @override
  String get categoryJuice => 'Jus';

  @override
  String available(String count) {
    return 'Dispo : $count';
  }

  @override
  String get outOfStock => 'Épuisé';

  @override
  String get price => 'Prix';

  @override
  String get quantity => 'Quantité';

  @override
  String quantityIn(String unit) {
    return 'Quantité ($unit)';
  }

  @override
  String get productionTitle => 'Production du matin';

  @override
  String get productionAlreadyToday => 'Déjà enregistré aujourd\'hui';

  @override
  String get productionSave => 'Enregistrer la production';

  @override
  String get productionConfirmTitle => 'Enregistrer cette production ?';

  @override
  String get productionSaved => 'Production enregistrée';

  @override
  String get productionNothing => 'Indiquez au moins une quantité';

  @override
  String deleteLotConfirm(String quantity, String product) {
    return 'Supprimer ce lot : $quantity × $product ?';
  }

  @override
  String get lotDeleted => 'Lot supprimé';

  @override
  String get saleTitle => 'Vente';

  @override
  String get saleTapToAdd => 'Touchez un produit pour l\'ajouter';

  @override
  String get saleValidate => 'Valider la vente';

  @override
  String get saleConfirmTitle => 'Valider cette vente ?';

  @override
  String saleSaved(String amount) {
    return 'Vente enregistrée : $amount';
  }

  @override
  String get saleClear => 'Vider';

  @override
  String get closingTitle => 'Clôture de la journée';

  @override
  String get closingInstructions => 'Comptez ce qui reste pour chaque produit.';

  @override
  String get closingRemaining => 'Reste';

  @override
  String get closingSold => 'Vendu';

  @override
  String get closingUnsold => 'Invendu';

  @override
  String get closingRecovered => 'Montant récupéré (revendu moins cher)';

  @override
  String get closingNotCounted => 'Pas encore compté';

  @override
  String get closingCountAll => 'Comptez tous les produits pour valider';

  @override
  String get closingValidate => 'Valider la clôture';

  @override
  String closingConfirmTitle(String date) {
    return 'Clôturer la journée du $date ?';
  }

  @override
  String get closingConfirmBody =>
      'Après validation, on ne peut plus vendre ni produire pour ce jour.';

  @override
  String get closingSaved => 'Journée clôturée';

  @override
  String get closingAlreadyClosed => 'Journée déjà clôturée';

  @override
  String get closingSalesTotal => 'Ventes du jour';

  @override
  String get closingWasteTotal => 'Invendus';

  @override
  String get closingLostValue => 'Valeur perdue';

  @override
  String get closingCancel => 'Annuler la clôture';

  @override
  String closingCancelConfirm(String date) {
    return 'Annuler la clôture du $date ? Les ventes et invendus calculés seront effacés pour recompter.';
  }

  @override
  String get closingCancelled => 'Clôture annulée : vous pouvez recompter';

  @override
  String get closingNothingToCount => 'Aucun produit en stock ce jour-là.';

  @override
  String get closingBlockedFuture => 'On ne peut pas clôturer une date future.';

  @override
  String get closingBlockedPeriod =>
      'Une journée plus récente est déjà clôturée.';

  @override
  String closingClosedBy(String name) {
    return 'Clôturée par $name';
  }

  @override
  String get closingAutomatic => 'Clôture automatique (sans comptage)';

  @override
  String expiringTonight(String count) {
    return 'Expire ce soir : $count';
  }

  @override
  String get previousDay => 'Jour précédent';

  @override
  String get nextDay => 'Jour suivant';

  @override
  String get wasteDeclare => 'Déclarer un produit abîmé';

  @override
  String get wasteDamaged => 'Abîmé';

  @override
  String get wasteOther => 'Autre';

  @override
  String get wasteExpired => 'Périmé';

  @override
  String get wasteReason => 'Motif';

  @override
  String get wasteSaved => 'Invendu enregistré';

  @override
  String get ingredientsTitle => 'Ingrédients';

  @override
  String get ingredientStock => 'Stock';

  @override
  String get ingredientThreshold => 'Seuil d\'alerte';

  @override
  String get ingredientLow => 'Bientôt épuisé';

  @override
  String get ingredientPurchase => 'Achat';

  @override
  String get ingredientUsage => 'Utilisation';

  @override
  String ingredientPurchaseTitle(String name) {
    return 'Achat : $name';
  }

  @override
  String ingredientUsageTitle(String name) {
    return 'Utilisation : $name';
  }

  @override
  String get totalPaid => 'Total payé';

  @override
  String get unitPrice => 'Prix unitaire';

  @override
  String get priceMode => 'Je connais…';

  @override
  String get supplier => 'Fournisseur (facultatif)';

  @override
  String get purchaseSaved => 'Achat enregistré';

  @override
  String get usageSaved => 'Utilisation enregistrée';

  @override
  String get purchases => 'Achats';

  @override
  String get usages => 'Utilisations';

  @override
  String get ingredientNew => 'Nouvel ingrédient';

  @override
  String get nameFr => 'Nom en français';

  @override
  String get nameMg => 'Nom en malgache';

  @override
  String get unit => 'Unité';

  @override
  String get unitKg => 'kg';

  @override
  String get unitG => 'g';

  @override
  String get unitL => 'litre';

  @override
  String get unitPiece => 'pièce';

  @override
  String get unitSachet => 'sachet';

  @override
  String get expensesTitle => 'Dépenses';

  @override
  String get expenseNew => 'Nouvelle dépense';

  @override
  String get expenseCategory => 'Catégorie';

  @override
  String get catElectricity => 'Électricité';

  @override
  String get catRent => 'Loyer';

  @override
  String get catTransport => 'Transport';

  @override
  String get catPackaging => 'Emballages';

  @override
  String get catOther => 'Autre';

  @override
  String get expenseLabel => 'Libellé';

  @override
  String get amount => 'Montant';

  @override
  String get expenseMonth => 'Mois concerné';

  @override
  String get dueDate => 'Date limite de paiement';

  @override
  String get alreadyPaid => 'Déjà payée';

  @override
  String paidOn(String date) {
    return 'Payée le $date';
  }

  @override
  String dueOn(String date) {
    return 'À payer avant le $date';
  }

  @override
  String get statusPaid => 'Payée';

  @override
  String get statusDue => 'À payer';

  @override
  String get statusOverdue => 'En retard';

  @override
  String get markPaid => 'Marquer comme payée';

  @override
  String markPaidConfirm(String label) {
    return 'Marquer « $label » comme payée aujourd\'hui ?';
  }

  @override
  String get expenseSaved => 'Dépense enregistrée';

  @override
  String deleteConfirm(String label) {
    return 'Supprimer « $label » ?';
  }

  @override
  String get deleted => 'Supprimé';

  @override
  String get monthTotal => 'Total du mois';

  @override
  String get unpaidTotal => 'Reste à payer';

  @override
  String get noExpenses => 'Aucune dépense ce mois-ci';

  @override
  String get employeesTitle => 'Employés';

  @override
  String get employeeNew => 'Nouvel employé';

  @override
  String get employeeName => 'Nom';

  @override
  String get employeePhone => 'Téléphone (facultatif)';

  @override
  String get employeeRole => 'Poste';

  @override
  String get rolePreparation => 'Préparation';

  @override
  String get roleSales => 'Vente';

  @override
  String get roleDelivery => 'Livraison';

  @override
  String get roleOther => 'Autre';

  @override
  String get hiredOn => 'Date d\'embauche';

  @override
  String get leftOn => 'Date de départ';

  @override
  String get monthlySalary => 'Salaire mensuel';

  @override
  String get balanceDue => 'Reste à payer';

  @override
  String get advance => 'Avance';

  @override
  String unpaidMonths(String months) {
    return '$months mois non payé(s)';
  }

  @override
  String get upToDate => 'À jour';

  @override
  String get totalDue => 'Total dû aux employés';

  @override
  String get accrued => 'Salaire gagné';

  @override
  String get paid => 'Déjà payé';

  @override
  String get currentSalary => 'Salaire actuel';

  @override
  String get pay => 'Payer';

  @override
  String payTitle(String name) {
    return 'Paiement : $name';
  }

  @override
  String get paymentSaved => 'Paiement enregistré';

  @override
  String get note => 'Remarque (facultatif)';

  @override
  String get changeSalary => 'Changer le salaire';

  @override
  String get newSalary => 'Nouveau salaire mensuel';

  @override
  String get effectiveFrom => 'À partir du';

  @override
  String get salaryChanged => 'Salaire modifié';

  @override
  String get paymentHistory => 'Historique des paiements';

  @override
  String get salaryHistory => 'Historique des salaires';

  @override
  String get noPayments => 'Aucun paiement';

  @override
  String leftCompany(String date) {
    return 'Parti le $date';
  }

  @override
  String get markLeft => 'Enregistrer le départ';

  @override
  String get reportsTitle => 'Rapports';

  @override
  String get week => 'Semaine';

  @override
  String get month => 'Mois';

  @override
  String weekLabel(String from, String to) {
    return 'Du $from au $to';
  }

  @override
  String get previousPeriod => 'Période précédente';

  @override
  String get nextPeriod => 'Période suivante';

  @override
  String get profit => 'Bénéfice';

  @override
  String get loss => 'Perte';

  @override
  String get revenue => 'Recettes';

  @override
  String get charges => 'Charges';

  @override
  String get ingredientsCharge => 'Ingrédients';

  @override
  String get salaries => 'Salaires';

  @override
  String partialUntil(String date) {
    return 'Période en cours : calculé jusqu\'au $date';
  }

  @override
  String get topProducts => 'Meilleures ventes';

  @override
  String get unsold => 'Invendus';

  @override
  String get unsoldValue => 'Valeur des invendus (non déduite)';

  @override
  String get revenueVsCharges => 'Recettes et charges par jour';

  @override
  String get productsTitle => 'Produits';

  @override
  String get productNew => 'Nouveau produit';

  @override
  String get category => 'Catégorie';

  @override
  String get format => 'Format';

  @override
  String get shelfLife => 'Se conserve (jours)';

  @override
  String get shelfLifeHelp => '1 = à vendre le jour même';

  @override
  String get active => 'Actif';

  @override
  String get inactive => 'Désactivé';

  @override
  String get productSaved => 'Produit enregistré';

  @override
  String get usersTitle => 'Comptes';

  @override
  String get userNew => 'Nouveau compte';

  @override
  String get userRole => 'Rôle';

  @override
  String get newPin => 'Nouveau code PIN (facultatif)';

  @override
  String get pinHelp => '4 à 6 chiffres';

  @override
  String get userSaved => 'Compte enregistré';

  @override
  String get fieldRequired => 'Obligatoire';

  @override
  String get invalidNumber => 'Nombre invalide';

  @override
  String get invalidPhone => 'Numéro invalide (ex. 034 12 345 67)';

  @override
  String get invalidPin => '4 à 6 chiffres';

  @override
  String get offline => 'Hors ligne';

  @override
  String pendingOps(String count) {
    return '$count en attente d\'envoi';
  }

  @override
  String rejectedOps(String count) {
    return '$count refusée(s) par le serveur : à vérifier';
  }

  @override
  String saleQueued(String amount) {
    return 'Pas de connexion : vente de $amount gardée sur le téléphone, envoyée dès le retour du réseau.';
  }

  @override
  String get productionQueued =>
      'Pas de connexion : production gardée sur le téléphone, envoyée dès le retour du réseau.';

  @override
  String get outboxTitle => 'En attente d\'envoi';

  @override
  String get outboxHint =>
      'Les ventes et la production faites sans connexion sont gardées ici, puis envoyées automatiquement dès que le serveur répond.';

  @override
  String get outboxEmpty => 'Tout est envoyé.';

  @override
  String get outboxSendNow => 'Envoyer maintenant';

  @override
  String get outboxStillOffline =>
      'Toujours pas de connexion. Nouvel essai automatique dans quelques secondes.';

  @override
  String get outboxPending => 'En attente';

  @override
  String get outboxRejected => 'Refusée';

  @override
  String get outboxDiscardConfirm =>
      'Supprimer cette opération ? Elle ne sera jamais envoyée.';

  @override
  String closingPendingOps(String count) {
    return '$count opération(s) pas encore envoyée(s) : envoyez-les avant de clôturer, sinon le compte serait faux.';
  }

  @override
  String logoutPendingOps(String count) {
    return '$count opération(s) en attente seront envoyées à la prochaine connexion.';
  }

  @override
  String get invalidUrl => 'Adresse invalide';
}
