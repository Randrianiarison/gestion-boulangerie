import 'package:boulangerie_app/models/dashboard.dart';
import 'package:boulangerie_app/models/employee.dart';
import 'package:boulangerie_app/models/report.dart';
import 'package:boulangerie_app/models/stock.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _product({int id = 1, int price = 800, String format = 'piece', String category = 'bread'}) => {
      'id': id,
      'category': category,
      'name_fr': 'Baguette',
      'name_mg': 'Mofo lava',
      'format': format,
      'unit_price': price,
      'shelf_life_days': 1,
      'active': true,
    };

void main() {
  group('aperçu de la clôture (FIFO)', () {
    // Pain de mie : 30 disponibles dont 10 expirent ce soir.
    final row = StockRow.fromJson({'product': _product(), 'available': 30, 'expiring': 10, 'stale': 0});

    test('vendu = disponible - restant', () {
      expect(row.soldFor(12), 18);
    });

    test('les lots qui expirent sont vendus en premier', () {
      expect(row.unsoldFor(12), 0); // 18 vendus couvrent les 10 qui expirent
      expect(row.unsoldFor(25), 5); // 5 vendus : 5 des 10 expirants restent invendus
    });

    test('un reste de lot déjà expiré est toujours invendu', () {
      final withStale = StockRow.fromJson({'product': _product(), 'available': 0, 'expiring': 0, 'stale': 4});
      expect(withStale.unsoldFor(0), 4);
    });
  });

  test('Laravel envoie 0 au lieu de 0.0 : les nombres sont lus via num', () {
    final summary = SalarySummary.fromJson({
      'accrued': 385000,
      'paid': 0,
      'balance': 385000,
      'current_rate': 155000,
      'unpaid_months': 2.5,
    });
    expect(summary.unpaidMonths, 2.5);

    final upToDate = SalarySummary.fromJson({
      'accrued': 10,
      'paid': 10,
      'balance': 0,
      'current_rate': 155000,
      'unpaid_months': 0,
    });
    expect(upToDate.unpaidMonths, 0.0);
  });

  test('le tableau de bord du staff n\'a ni factures ni salaires', () {
    final dashboard = Dashboard.fromJson({
      'data': {
        'date': '2026-10-22',
        'revenue_today': {
          'sales': 5000,
          'recovered': 0,
          'total': 5000,
          'by_category': {'bread': 5000, 'juice': 0},
        },
        'closing': {'closed_today': false, 'last_closed_on': '2026-10-21'},
        'stock': [
          {'product': _product(), 'available': 30, 'expiring': 30, 'stale': 0},
        ],
        'waste_today': {'quantity': 0, 'lost_value': 0, 'recovered': 0, 'items': []},
        'ingredient_alerts': [],
      },
    });

    expect(dashboard.revenueToday.byCategory['bread'], 5000);
    expect(dashboard.billsDue, isNull);
    expect(dashboard.salariesDueTotal, isNull);
    expect(dashboard.stock.single.product.name('mg'), 'Mofo lava');
  });

  test('rapport de la semaine', () {
    final report = Report.fromJson({
      'data': {
        'period': {'from': '2026-10-19', 'to': '2026-10-25', 'as_of': '2026-10-22', 'partial': true, 'type': 'week'},
        'revenue': {'sales': 40000, 'recovered': 0, 'total': 40000, 'by_category': {'bread': 40000, 'juice': 0}},
        'charges': {
          'ingredients': 0,
          'expenses': 0,
          'monthly_expenses': 0,
          'salaries': 20000,
          'total': 20000,
          'expenses_by_category': {'electricity': 0, 'rent': 0, 'transport': 0, 'packaging': 0, 'other': 0},
          'salaries_by_employee': [
            {'employee_id': 1, 'name': 'Hery', 'amount': 20000},
          ],
        },
        'profit': 20000,
        'top_products': [
          {
            'product_id': 1,
            'name_fr': 'Baguette',
            'name_mg': 'Mofo lava',
            'format': 'piece',
            'category': 'bread',
            'quantity': 50,
            'revenue': 40000,
          },
        ],
        'waste': {'quantity': 0, 'value': 0, 'recovered': 0},
        'series': [
          {'date': '2026-10-19', 'revenue': 0, 'charges': 5000},
        ],
      },
    });

    expect(report.partial, isTrue);
    expect(report.profit, 20000);
    expect(report.charges.salariesByEmployee.single.name, 'Hery');
    expect(report.topProducts.single.format, ProductFormat.piece);
    expect(report.series.single.date, DateTime(2026, 10, 19));
  });
}
