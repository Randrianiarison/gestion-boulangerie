import 'dashboard.dart';
import 'json.dart';
import 'stock.dart';

enum ReportPeriod { week, month }

class SalaryLine {
  const SalaryLine({required this.name, required this.amount});

  factory SalaryLine.fromJson(Json json) => SalaryLine(name: json['name'] as String, amount: asInt(json['amount']));

  final String name;
  final int amount;
}

class Charges {
  const Charges({
    required this.ingredients,
    required this.expenses,
    required this.monthlyExpenses,
    required this.salaries,
    required this.total,
    required this.expensesByCategory,
    required this.salariesByEmployee,
  });

  factory Charges.fromJson(Json json) => Charges(
        ingredients: asInt(json['ingredients']),
        expenses: asInt(json['expenses']),
        monthlyExpenses: asInt(json['monthly_expenses']),
        salaries: asInt(json['salaries']),
        total: asInt(json['total']),
        expensesByCategory: asIntMap(json['expenses_by_category']),
        salariesByEmployee: asList(json['salaries_by_employee'], SalaryLine.fromJson),
      );

  final int ingredients;
  final int expenses;
  final int monthlyExpenses;
  final int salaries;
  final int total;
  final Map<String, int> expensesByCategory;
  final List<SalaryLine> salariesByEmployee;
}

class TopProduct {
  const TopProduct({
    required this.nameFr,
    required this.nameMg,
    required this.format,
    this.size,
    required this.quantity,
    required this.revenue,
  });

  factory TopProduct.fromJson(Json json) => TopProduct(
        nameFr: json['name_fr'] as String,
        nameMg: json['name_mg'] as String,
        format: ProductFormat.values.byName(json['format'] as String),
        size: productSizeFromJson(json['size']),
        quantity: asInt(json['quantity']),
        revenue: asInt(json['revenue']),
      );

  final String nameFr;
  final String nameMg;
  final ProductFormat format;
  final ProductSize? size;
  final int quantity;
  final int revenue;

  String name(String languageCode) => languageCode == 'mg' ? nameMg : nameFr;
}

class SeriesPoint {
  const SeriesPoint({required this.date, required this.revenue, required this.charges});

  factory SeriesPoint.fromJson(Json json) => SeriesPoint(
        date: asDate(json['date']),
        revenue: asInt(json['revenue']),
        charges: asInt(json['charges']),
      );

  final DateTime date;
  final int revenue;
  final int charges;
}

/// GET /reports/summary : bénéfice d'une semaine ou d'un mois (comptabilité d'engagement).
class Report {
  const Report({
    required this.from,
    required this.to,
    required this.asOf,
    required this.partial,
    required this.revenue,
    required this.charges,
    required this.profit,
    required this.topProducts,
    required this.wasteQuantity,
    required this.wasteValue,
    required this.wasteRecovered,
    required this.series,
  });

  factory Report.fromJson(Json json) {
    final data = asJson(json['data']);
    final period = asJson(data['period']);
    final waste = asJson(data['waste']);

    return Report(
      from: asDate(period['from']),
      to: asDate(period['to']),
      asOf: asDate(period['as_of']),
      partial: period['partial'] as bool,
      revenue: Revenue.fromJson(asJson(data['revenue'])),
      charges: Charges.fromJson(asJson(data['charges'])),
      profit: asInt(data['profit']),
      topProducts: asList(data['top_products'], TopProduct.fromJson),
      wasteQuantity: asInt(waste['quantity']),
      wasteValue: asInt(waste['value']),
      wasteRecovered: asInt(waste['recovered']),
      series: asList(data['series'], SeriesPoint.fromJson),
    );
  }

  final DateTime from;
  final DateTime to;
  final DateTime asOf;
  final bool partial;
  final Revenue revenue;
  final Charges charges;
  final int profit;
  final List<TopProduct> topProducts;
  final int wasteQuantity;
  final int wasteValue;
  final int wasteRecovered;
  final List<SeriesPoint> series;
}
