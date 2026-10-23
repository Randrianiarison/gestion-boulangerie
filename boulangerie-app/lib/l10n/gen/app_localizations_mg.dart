// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malagasy (`mg`).
class AppLocalizationsMg extends AppLocalizations {
  AppLocalizationsMg([String locale = 'mg']) : super(locale);

  @override
  String get appTitle => 'Fivarotam-mofo';

  @override
  String get language => 'Fiteny';

  @override
  String get languageMalagasy => 'Malagasy';

  @override
  String get languageFrench => 'Français';

  @override
  String get loginTitle => 'Fidirana';

  @override
  String get phoneLabel => 'Laharana finday';

  @override
  String get pinLabel => 'Kaody PIN';

  @override
  String get loginButton => 'Hiditra';

  @override
  String get serverSettings => 'Adiresin\'ny serveur';

  @override
  String get serverUrlLabel => 'Adiresin\'ny API';

  @override
  String get serverUrlHelp => 'Émulateur Android : http://10.0.2.2:8000/api';

  @override
  String greeting(String name) {
    return 'Salama $name';
  }

  @override
  String get save => 'Tehirizo';

  @override
  String get saved => 'Voatahiry';

  @override
  String get paymentDate => 'Daty nandoavana';

  @override
  String get cancel => 'Aoka ihany';

  @override
  String get confirm => 'Hamafiso';

  @override
  String get yes => 'Eny';

  @override
  String get no => 'Tsia';

  @override
  String get close => 'Hidio';

  @override
  String get retry => 'Andramo indray';

  @override
  String get edit => 'Ovay';

  @override
  String get delete => 'Fafao';

  @override
  String get add => 'Ampio';

  @override
  String get loading => 'Miandry kely…';

  @override
  String get logout => 'Hivoaka';

  @override
  String get logoutConfirm => 'Hivoaka ve ianao?';

  @override
  String get settings => 'Fandrindrana';

  @override
  String connectedAs(String name) {
    return 'Tafiditra : $name';
  }

  @override
  String get roleOwner => 'Tompony';

  @override
  String get roleStaff => 'Mpiasa';

  @override
  String get today => 'Anio';

  @override
  String get yesterday => 'Omaly';

  @override
  String get date => 'Daty';

  @override
  String get total => 'Totaliny';

  @override
  String get noData => 'Tsy misy angona';

  @override
  String get errorNetwork =>
      'Tsy misy fifandraisana amin\'ny serveur. Jereo ny Wi-Fi na ny data, dia andramo indray.';

  @override
  String get errorTimeout => 'Ela loatra ny valin\'ny serveur. Andramo indray.';

  @override
  String get errorUnauthorized => 'Tapitra ny fidirana : midira indray.';

  @override
  String get errorForbidden => 'Ho an\'ny tompony ihany.';

  @override
  String get errorNotFound => 'Tsy hita.';

  @override
  String get errorServer =>
      'Nisy olana tamin\'ny serveur. Andramo indray any aoriana.';

  @override
  String get errorTooManyAttempts =>
      'Be loatra ny andrana. Miandrasa iray minitra.';

  @override
  String get errorBadResponse =>
      'Tsy mazava ny valin\'ny serveur. Jereo ny adiresin\'ny serveur ao amin\'ny fandrindrana.';

  @override
  String get errorUnknown => 'Nisy olana.';

  @override
  String get homeTitle => 'Fandraisana';

  @override
  String get revenueToday => 'Vola niditra anio';

  @override
  String get bread => 'Mofo';

  @override
  String get juice => 'Ranom-boankazo';

  @override
  String get recovered => 'Tsy lafo namidy mora';

  @override
  String get alerts => 'Fampitandremana';

  @override
  String get noAlerts => 'Tsy misy olana';

  @override
  String get closingNotDone => 'Mbola tsy voakatona ny andro';

  @override
  String get closingDone => 'Voakatona ny andro';

  @override
  String lowIngredients(String names) {
    return 'Akora efa ho lany : $names';
  }

  @override
  String get billsDue => 'Faktiora tokony haloa';

  @override
  String get salariesDue => 'Karama tsy mbola voaloa';

  @override
  String get stockToday => 'Tahiry anio';

  @override
  String get menuProduction => 'Famokarana';

  @override
  String get menuSale => 'Varotra';

  @override
  String get menuClosing => 'Fanakatonana';

  @override
  String get menuIngredients => 'Akora';

  @override
  String get menuExpenses => 'Fandaniana';

  @override
  String get menuEmployees => 'Mpiasa';

  @override
  String get menuReports => 'Tatitra';

  @override
  String get menuProducts => 'Vokatra';

  @override
  String get menuUsers => 'Kaonty';

  @override
  String get formatPiece => 'isany';

  @override
  String get formatGlass => 'vera';

  @override
  String get formatBottle => 'tavoahangy';

  @override
  String get size => 'Habe';

  @override
  String get sizeNone => 'Habe tokana';

  @override
  String get sizeSmall => 'Kely';

  @override
  String get sizeMedium => 'Antonony';

  @override
  String get sizeLarge => 'Lehibe';

  @override
  String get categoryBread => 'Mofo';

  @override
  String get categoryJuice => 'Ranom-boankazo';

  @override
  String available(String count) {
    return 'Misy : $count';
  }

  @override
  String get outOfStock => 'Lany';

  @override
  String get price => 'Vidiny';

  @override
  String get quantity => 'Habetsahana';

  @override
  String quantityIn(String unit) {
    return 'Habetsahana ($unit)';
  }

  @override
  String get productionTitle => 'Famokarana maraina';

  @override
  String get productionAlreadyToday => 'Efa voasoratra anio';

  @override
  String get productionSave => 'Tehirizo ny famokarana';

  @override
  String get productionConfirmTitle => 'Hotehirizina ve ity famokarana ity?';

  @override
  String get productionSaved => 'Voatahiry ny famokarana';

  @override
  String get productionNothing => 'Asio isa iray farafahakeliny';

  @override
  String deleteLotConfirm(String quantity, String product) {
    return 'Hofafana ve ity : $quantity × $product?';
  }

  @override
  String get lotDeleted => 'Voafafa';

  @override
  String get saleTitle => 'Varotra';

  @override
  String get saleTapToAdd => 'Tsindrio ny vokatra hampidirana azy';

  @override
  String get saleValidate => 'Hamafiso ny varotra';

  @override
  String get saleConfirmTitle => 'Hamafisina ve ity varotra ity?';

  @override
  String saleSaved(String amount) {
    return 'Voasoratra ny varotra : $amount';
  }

  @override
  String get saleClear => 'Fafao daholo';

  @override
  String get closingTitle => 'Fanakatonana ny andro';

  @override
  String get closingInstructions =>
      'Isao izay sisa amin\'ny vokatra tsirairay.';

  @override
  String get closingRemaining => 'Sisa';

  @override
  String get closingSold => 'Lafo';

  @override
  String get closingUnsold => 'Tsy lafo';

  @override
  String get closingRecovered => 'Vola niverina (namidy mora)';

  @override
  String get closingNotCounted => 'Mbola tsy voaisa';

  @override
  String get closingCountAll => 'Isao daholo ny vokatra vao afaka mamafy';

  @override
  String get closingValidate => 'Hamafiso ny fanakatonana';

  @override
  String closingConfirmTitle(String date) {
    return 'Hakatona ve ny andro $date?';
  }

  @override
  String get closingConfirmBody =>
      'Rehefa voakatona, tsy azo hivarotana na hamokarana intsony io andro io.';

  @override
  String get closingSaved => 'Voakatona ny andro';

  @override
  String get closingAlreadyClosed => 'Efa voakatona ny andro';

  @override
  String get closingSalesTotal => 'Varotra tamin\'ity andro ity';

  @override
  String get closingWasteTotal => 'Tsy lafo';

  @override
  String get closingLostValue => 'Vola very';

  @override
  String get closingCancel => 'Foano ny fanakatonana';

  @override
  String closingCancelConfirm(String date) {
    return 'Hofoanana ve ny fanakatonana ny $date? Hofafana ny varotra sy ny tsy lafo voaisa mba hanisana indray.';
  }

  @override
  String get closingCancelled =>
      'Voafoana ny fanakatonana : azonao isaina indray';

  @override
  String get closingNothingToCount => 'Tsy nisy vokatra tamin\'io andro io.';

  @override
  String get closingBlockedFuture => 'Tsy azo akatona ny daty mbola ho avy.';

  @override
  String get closingBlockedPeriod =>
      'Efa voakatona ny andro iray taty aoriana.';

  @override
  String closingClosedBy(String name) {
    return 'Nakaton\'i $name';
  }

  @override
  String get closingAutomatic => 'Fanakatonana ho azy (tsy nisy fanisana)';

  @override
  String expiringTonight(String count) {
    return 'Lany daty anio hariva : $count';
  }

  @override
  String get previousDay => 'Andro teo aloha';

  @override
  String get nextDay => 'Andro manaraka';

  @override
  String get wasteDeclare => 'Hanambara vokatra simba';

  @override
  String get wasteDamaged => 'Simba';

  @override
  String get wasteOther => 'Hafa';

  @override
  String get wasteExpired => 'Lany daty';

  @override
  String get wasteReason => 'Antony';

  @override
  String get wasteSaved => 'Voasoratra ny tsy lafo';

  @override
  String get ingredientsTitle => 'Akora';

  @override
  String get ingredientStock => 'Tahiry';

  @override
  String get ingredientThreshold => 'Fetra fampitandremana';

  @override
  String get ingredientLow => 'Efa ho lany';

  @override
  String get ingredientPurchase => 'Fividianana';

  @override
  String get ingredientUsage => 'Fampiasana';

  @override
  String ingredientPurchaseTitle(String name) {
    return 'Fividianana : $name';
  }

  @override
  String ingredientUsageTitle(String name) {
    return 'Fampiasana : $name';
  }

  @override
  String get totalPaid => 'Vola naloa rehetra';

  @override
  String get unitPrice => 'Vidin\'ny iray';

  @override
  String get priceMode => 'Fantatro ny…';

  @override
  String get supplier => 'Mpamatsy (tsy voatery)';

  @override
  String get purchaseSaved => 'Voasoratra ny fividianana';

  @override
  String get usageSaved => 'Voasoratra ny fampiasana';

  @override
  String get purchases => 'Fividianana';

  @override
  String get usages => 'Fampiasana';

  @override
  String get ingredientNew => 'Akora vaovao';

  @override
  String get nameFr => 'Anarana amin\'ny teny frantsay';

  @override
  String get nameMg => 'Anarana amin\'ny teny malagasy';

  @override
  String get unit => 'Refy';

  @override
  String get unitKg => 'kg';

  @override
  String get unitG => 'g';

  @override
  String get unitL => 'litatra';

  @override
  String get unitPiece => 'isany';

  @override
  String get unitSachet => 'fonosana';

  @override
  String get expensesTitle => 'Fandaniana';

  @override
  String get expenseNew => 'Fandaniana vaovao';

  @override
  String get expenseCategory => 'Sokajy';

  @override
  String get catElectricity => 'Herinaratra';

  @override
  String get catRent => 'Hofan-trano';

  @override
  String get catTransport => 'Fitaterana';

  @override
  String get catPackaging => 'Fonosana';

  @override
  String get catOther => 'Hafa';

  @override
  String get expenseLabel => 'Anarana';

  @override
  String get amount => 'Vola';

  @override
  String get expenseMonth => 'Volana';

  @override
  String get dueDate => 'Daty farany handoavana';

  @override
  String get alreadyPaid => 'Efa voaloa';

  @override
  String paidOn(String date) {
    return 'Naloa ny $date';
  }

  @override
  String dueOn(String date) {
    return 'Aloa alohan\'ny $date';
  }

  @override
  String get statusPaid => 'Voaloa';

  @override
  String get statusDue => 'Tokony haloa';

  @override
  String get statusOverdue => 'Tara';

  @override
  String get markPaid => 'Marihina ho voaloa';

  @override
  String markPaidConfirm(String label) {
    return 'Marihina ho voaloa anio ve « $label »?';
  }

  @override
  String get expenseSaved => 'Voasoratra ny fandaniana';

  @override
  String deleteConfirm(String label) {
    return 'Hofafana ve « $label »?';
  }

  @override
  String get deleted => 'Voafafa';

  @override
  String get monthTotal => 'Totalin\'ny volana';

  @override
  String get unpaidTotal => 'Mbola tsy voaloa';

  @override
  String get noExpenses => 'Tsy misy fandaniana amin\'ity volana ity';

  @override
  String get employeesTitle => 'Mpiasa';

  @override
  String get employeeNew => 'Mpiasa vaovao';

  @override
  String get employeeName => 'Anarana';

  @override
  String get employeePhone => 'Finday (tsy voatery)';

  @override
  String get employeeRole => 'Asa';

  @override
  String get rolePreparation => 'Fanomanana';

  @override
  String get roleSales => 'Varotra';

  @override
  String get roleDelivery => 'Fanaterana';

  @override
  String get roleOther => 'Hafa';

  @override
  String get hiredOn => 'Daty nidirany niasa';

  @override
  String get leftOn => 'Daty nialany';

  @override
  String get monthlySalary => 'Karama isam-bolana';

  @override
  String get balanceDue => 'Mbola tokony haloa';

  @override
  String get advance => 'Mialoha';

  @override
  String unpaidMonths(String months) {
    return '$months volana tsy voaloa';
  }

  @override
  String get upToDate => 'Voaloa daholo';

  @override
  String get totalDue => 'Karama tsy voaloa rehetra';

  @override
  String get accrued => 'Karama azony';

  @override
  String get paid => 'Efa naloa';

  @override
  String get currentSalary => 'Karama ankehitriny';

  @override
  String get pay => 'Handoa';

  @override
  String payTitle(String name) {
    return 'Fandoavana : $name';
  }

  @override
  String get paymentSaved => 'Voasoratra ny fandoavana';

  @override
  String get note => 'Fanamarihana (tsy voatery)';

  @override
  String get changeSalary => 'Hanova karama';

  @override
  String get newSalary => 'Karama isam-bolana vaovao';

  @override
  String get effectiveFrom => 'Manomboka ny';

  @override
  String get salaryChanged => 'Voaova ny karama';

  @override
  String get paymentHistory => 'Tantaran\'ny fandoavana';

  @override
  String get salaryHistory => 'Tantaran\'ny karama';

  @override
  String get noPayments => 'Tsy mbola nisy fandoavana';

  @override
  String leftCompany(String date) {
    return 'Niala ny $date';
  }

  @override
  String get markLeft => 'Hanoratra ny fialany';

  @override
  String get reportsTitle => 'Tatitra';

  @override
  String get week => 'Herinandro';

  @override
  String get month => 'Volana';

  @override
  String weekLabel(String from, String to) {
    return '$from - $to';
  }

  @override
  String get previousPeriod => 'Teo aloha';

  @override
  String get nextPeriod => 'Manaraka';

  @override
  String get profit => 'Tombony';

  @override
  String get loss => 'Fatiantoka';

  @override
  String get revenue => 'Vola niditra';

  @override
  String get charges => 'Vola nivoaka';

  @override
  String get ingredientsCharge => 'Akora';

  @override
  String get salaries => 'Karama';

  @override
  String partialUntil(String date) {
    return 'Mbola mandeha : voakajy hatramin\'ny $date';
  }

  @override
  String get topProducts => 'Tena lafo indrindra';

  @override
  String get unsold => 'Tsy lafo';

  @override
  String get unsoldValue => 'Vidin\'ny tsy lafo (tsy esorina)';

  @override
  String get revenueVsCharges => 'Vola niditra sy nivoaka isan\'andro';

  @override
  String get productsTitle => 'Vokatra';

  @override
  String get productNew => 'Vokatra vaovao';

  @override
  String get category => 'Sokajy';

  @override
  String get format => 'Endrika';

  @override
  String get shelfLife => 'Faharetana (andro)';

  @override
  String get shelfLifeHelp => '1 = amidy anio ihany';

  @override
  String get active => 'Mavitrika';

  @override
  String get inactive => 'Najanona';

  @override
  String get productSaved => 'Voatahiry ny vokatra';

  @override
  String get usersTitle => 'Kaonty';

  @override
  String get userNew => 'Kaonty vaovao';

  @override
  String get userRole => 'Andraikitra';

  @override
  String get newPin => 'Kaody PIN vaovao (tsy voatery)';

  @override
  String get pinHelp => 'Tarehimarika 4 ka hatramin\'ny 6';

  @override
  String get userSaved => 'Voatahiry ny kaonty';

  @override
  String get fieldRequired => 'Tsy maintsy fenoina';

  @override
  String get invalidNumber => 'Tsy isa marina';

  @override
  String get invalidPhone => 'Diso ny laharana (oh. 034 12 345 67)';

  @override
  String get invalidPin => 'Tarehimarika 4 ka hatramin\'ny 6';

  @override
  String get invalidUrl => 'Diso ny adiresy';
}
