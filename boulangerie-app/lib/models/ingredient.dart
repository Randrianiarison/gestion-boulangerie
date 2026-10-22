import 'json.dart';

enum IngredientUnit { kg, g, l, piece, sachet }

class Ingredient {
  const Ingredient({
    required this.id,
    required this.nameFr,
    required this.nameMg,
    required this.unit,
    required this.alertThreshold,
    required this.active,
    required this.stock,
    required this.lowStock,
    this.purchases = const [],
    this.usages = const [],
  });

  factory Ingredient.fromJson(Json json) => Ingredient(
        id: asInt(json['id']),
        nameFr: json['name_fr'] as String,
        nameMg: json['name_mg'] as String,
        unit: IngredientUnit.values.byName(json['unit'] as String),
        alertThreshold: asDouble(json['alert_threshold']),
        active: json['active'] as bool,
        stock: asDouble(json['stock']),
        lowStock: json['low_stock'] as bool,
        purchases: asList(json['purchases'], IngredientPurchase.fromJson),
        usages: asList(json['usages'], IngredientUsage.fromJson),
      );

  final int id;
  final String nameFr;
  final String nameMg;
  final IngredientUnit unit;
  final double alertThreshold;
  final bool active;
  final double stock;
  final bool lowStock;
  final List<IngredientPurchase> purchases;
  final List<IngredientUsage> usages;

  String name(String languageCode) => languageCode == 'mg' ? nameMg : nameFr;
}

class IngredientPurchase {
  const IngredientPurchase({
    required this.id,
    required this.purchasedOn,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.supplier,
  });

  factory IngredientPurchase.fromJson(Json json) => IngredientPurchase(
        id: asInt(json['id']),
        purchasedOn: asDate(json['purchased_on']),
        quantity: asDouble(json['quantity']),
        unitPrice: asInt(json['unit_price']),
        total: asInt(json['total']),
        supplier: json['supplier'] as String?,
      );

  final int id;
  final DateTime purchasedOn;
  final double quantity;
  final int unitPrice;
  final int total;
  final String? supplier;
}

class IngredientUsage {
  const IngredientUsage({required this.id, required this.usedOn, required this.quantity, required this.note});

  factory IngredientUsage.fromJson(Json json) => IngredientUsage(
        id: asInt(json['id']),
        usedOn: asDate(json['used_on']),
        quantity: asDouble(json['quantity']),
        note: json['note'] as String?,
      );

  final int id;
  final DateTime usedOn;
  final double quantity;
  final String? note;
}
