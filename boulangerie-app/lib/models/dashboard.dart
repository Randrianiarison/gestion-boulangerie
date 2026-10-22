import 'expense.dart';
import 'ingredient.dart';
import 'json.dart';
import 'stock.dart';

class Revenue {
  const Revenue({required this.sales, required this.recovered, required this.total, required this.byCategory});

  factory Revenue.fromJson(Json json) => Revenue(
        sales: asInt(json['sales']),
        recovered: asInt(json['recovered']),
        total: asInt(json['total']),
        byCategory: asIntMap(json['by_category']),
      );

  final int sales;
  final int recovered;
  final int total;
  final Map<String, int> byCategory;
}

class Dashboard {
  const Dashboard({
    required this.date,
    required this.revenueToday,
    required this.closedToday,
    required this.stock,
    required this.wasteQuantity,
    required this.ingredientAlerts,
    required this.billsDue,
    required this.salariesDueTotal,
  });

  factory Dashboard.fromJson(Json json) {
    final data = asJson(json['data']);
    final closing = asJson(data['closing']);
    final waste = asJson(data['waste_today']);

    return Dashboard(
      date: asDate(data['date']),
      revenueToday: Revenue.fromJson(asJson(data['revenue_today'])),
      closedToday: closing['closed_today'] as bool,
      stock: asList(data['stock'], StockRow.fromJson),
      wasteQuantity: asInt(waste['quantity']),
      ingredientAlerts: asList(data['ingredient_alerts'], Ingredient.fromJson),
      // Absents pour le staff : factures et salaires sont réservés à l'owner.
      billsDue: data.containsKey('bills_due') ? asList(data['bills_due'], Expense.fromJson) : null,
      salariesDueTotal: data.containsKey('salaries_due_total') ? asInt(data['salaries_due_total']) : null,
    );
  }

  final DateTime date;
  final Revenue revenueToday;
  final bool closedToday;
  final List<StockRow> stock;
  final int wasteQuantity;
  final List<Ingredient> ingredientAlerts;
  final List<Expense>? billsDue;
  final int? salariesDueTotal;
}
