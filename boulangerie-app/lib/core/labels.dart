import 'package:flutter/widgets.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/employee.dart';
import '../models/expense.dart';
import '../models/ingredient.dart';
import '../models/stock.dart';
import '../models/user.dart';
import 'format.dart';

extension ContextShortcuts on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// 'mg' ou 'fr'
  String get lang => Localizations.localeOf(this).languageCode;

  DateLabels get dates => DateLabels(lang);
}

/// Libellés traduits des valeurs envoyées par l'API.
extension EnumLabels on AppLocalizations {
  String formatLabel(ProductFormat format) => switch (format) {
        ProductFormat.piece => formatPiece,
        ProductFormat.glass => formatGlass,
        ProductFormat.bottle => formatBottle,
      };

  String sizeLabel(ProductSize size) => switch (size) {
        ProductSize.small => sizeSmall,
        ProductSize.medium => sizeMedium,
        ProductSize.large => sizeLarge,
      };

  String categoryLabel(ProductCategory category) => switch (category) {
        ProductCategory.bread => categoryBread,
        ProductCategory.juice => categoryJuice,
      };

  String unitLabel(IngredientUnit unit) => switch (unit) {
        IngredientUnit.kg => unitKg,
        IngredientUnit.g => unitG,
        IngredientUnit.l => unitL,
        IngredientUnit.piece => unitPiece,
        IngredientUnit.sachet => unitSachet,
      };

  String expenseCategoryLabel(ExpenseCategory category) => switch (category) {
        ExpenseCategory.electricity => catElectricity,
        ExpenseCategory.rent => catRent,
        ExpenseCategory.transport => catTransport,
        ExpenseCategory.packaging => catPackaging,
        ExpenseCategory.other => catOther,
      };

  String expenseStatusLabel(ExpenseStatus status) => switch (status) {
        ExpenseStatus.paid => statusPaid,
        ExpenseStatus.due => statusDue,
        ExpenseStatus.overdue => statusOverdue,
      };

  String employeeRoleLabel(EmployeeRole role) => switch (role) {
        EmployeeRole.preparation => rolePreparation,
        EmployeeRole.sales => roleSales,
        EmployeeRole.delivery => roleDelivery,
        EmployeeRole.other => roleOther,
      };

  String userRoleLabel(UserRole role) => switch (role) {
        UserRole.owner => roleOwner,
        UserRole.staff => roleStaff,
      };

  String wasteReasonLabel(WasteReason reason) => switch (reason) {
        WasteReason.expired => wasteExpired,
        WasteReason.damaged => wasteDamaged,
        WasteReason.other => wasteOther,
      };
}

/// « Baguette », « Jus de papaye · verre », « Pain au chocolat · grand ».
String productLabel(
  BuildContext context, {
  required String nameFr,
  required String nameMg,
  required ProductFormat format,
  ProductSize? size,
}) {
  final l10n = context.l10n;
  return [
    context.lang == 'mg' ? nameMg : nameFr,
    if (format != ProductFormat.piece) l10n.formatLabel(format),
    if (size != null) l10n.sizeLabel(size).toLowerCase(),
  ].join(' · ');
}

extension ProductLabel on Product {
  String label(BuildContext context) =>
      productLabel(context, nameFr: nameFr, nameMg: nameMg, format: format, size: size);
}
