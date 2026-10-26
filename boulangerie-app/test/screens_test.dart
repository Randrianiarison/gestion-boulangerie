import 'dart:async';
import 'dart:convert';

import 'package:boulangerie_app/app.dart';
import 'package:boulangerie_app/core/api_client.dart';
import 'package:boulangerie_app/core/api_exception.dart';
import 'package:boulangerie_app/core/format.dart';
import 'package:boulangerie_app/core/settings.dart';
import 'package:boulangerie_app/data/bakery_api.dart';
import 'package:boulangerie_app/data/outbox.dart';
import 'package:boulangerie_app/data/providers.dart';
import 'package:boulangerie_app/models/dashboard.dart';
import 'package:boulangerie_app/models/employee.dart';
import 'package:boulangerie_app/models/expense.dart';
import 'package:boulangerie_app/models/ingredient.dart';
import 'package:boulangerie_app/models/json.dart';
import 'package:boulangerie_app/models/report.dart';
import 'package:boulangerie_app/models/stock.dart';
import 'package:boulangerie_app/models/user.dart';
import 'package:boulangerie_app/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Données factices, au format exact de l'API ------------------------------------

Map<String, dynamic> _product(int id, String category, String fr, String mg, String format, int price,
        [int days = 1, String? size, int? volumeMl]) =>
    {
      'id': id,
      'category': category,
      'name_fr': fr,
      'name_mg': mg,
      'format': format,
      'size': size,
      'volume_ml': volumeMl,
      'unit_price': price,
      'shelf_life_days': days,
      'active': true,
    };

final _products = [
  _product(1, 'bread', 'Baguette', 'Mofo lava', 'piece', 800),
  _product(2, 'bread', 'Pain de mie', 'Mofo malefaka', 'piece', 3000, 3),
  // Jus à la bouteille : chaque bouteille a sa contenance et son prix.
  _product(3, 'juice', "Jus d'orange", 'Ranom-boasary', 'bottle', 5000, 2, null, 1000),
  _product(4, 'juice', "Jus d'avocat", 'Ranon-javoka', 'bottle', 4000, 2, null, 500),
  // Même pain en deux tailles, prix différents.
  _product(5, 'bread', 'Pain au chocolat', 'Mofo sôkôla', 'piece', 1000, 2, 'small'),
  _product(6, 'bread', 'Pain au chocolat', 'Mofo sôkôla', 'piece', 1500, 2, 'large'),
];

Map<String, dynamic> _row(int index, int available, int expiring) =>
    {'product': _products[index], 'available': available, 'expiring': expiring, 'stale': 0};

final _stockRows = [_row(0, 45, 45), _row(1, 30, 10), _row(2, 0, 0), _row(3, 8, 0), _row(4, 12, 0), _row(5, 9, 0)];

final _flour = {
  'id': 1,
  'name_fr': 'Farine',
  'name_mg': 'Lafarinina',
  'unit': 'kg',
  'alert_threshold': 25,
  'active': true,
  'stock': 22.5,
  'low_stock': true,
};

final _electricity = {
  'id': 1,
  'category': 'electricity',
  'label': 'JIRAMA 10/2026',
  'amount': 62000,
  'expense_date': '2026-10-05',
  'period_month': '2026-10',
  'due_date': '2026-10-20',
  'paid_at': null,
  'status': 'overdue',
};

final _hery = {
  'id': 1,
  'name': 'Hery',
  'phone': '0331234567',
  'role': 'preparation',
  'hired_on': '2026-04-01',
  'left_on': null,
  'active': true,
  'salary': {'as_of': '2026-10-22', 'accrued': 1221935, 'paid': 720000, 'balance': 501935, 'current_rate': 200000, 'unpaid_months': 2.5},
};

final _owner = {'id': 1, 'name': 'Propriétaire', 'phone': '0340000001', 'role': 'owner', 'active': true};

class _FakeApi extends BakeryApi {
  _FakeApi()
      : super(ApiClient(baseUrl: () => 'http://test', token: () => null, languageCode: () => 'fr', onUnauthorized: () {}));

  /// Simule une coupure : les ventes et productions ne peuvent plus partir.
  bool offline = false;
  final List<OutboxOperation> sent = [];

  @override
  Future<Json> sendOperation(OutboxOperation operation) async {
    if (offline) throw const ApiException(ApiErrorKind.network);
    sent.add(operation);
    return const {};
  }

  final List<Json> savedProducts = [];

  @override
  Future<void> saveProduct(int? id, Json data) async => savedProducts.add(data);

  @override
  Future<Dashboard> dashboard() async => Dashboard.fromJson({
        'data': {
          'date': '2026-10-22',
          'revenue_today': {
            'sales': 1250000,
            'recovered': 4000,
            'total': 1254000,
            'by_category': {'bread': 850000, 'juice': 400000},
          },
          'closing': {'closed_today': false, 'last_closed_on': '2026-10-21'},
          'stock': _stockRows,
          'waste_today': {'quantity': 0, 'lost_value': 0, 'recovered': 0, 'items': []},
          'ingredient_alerts': [_flour],
          'bills_due': [_electricity],
          'salaries_due_total': 501935,
        },
      });

  @override
  Future<List<Product>> products({bool activeOnly = false}) async => _products.map(Product.fromJson).toList();

  @override
  Future<List<StockRow>> stock() async => _stockRows.map(StockRow.fromJson).toList();

  @override
  Future<List<StockLot>> productionOn(DateTime date) async => [
        StockLot.fromJson({
          'id': 1,
          'product': _products[0],
          'produced_on': '2026-10-22',
          'expires_on': '2026-10-22',
          'quantity_produced': 120,
          'quantity_remaining': 120,
          'untouched': true,
        }),
      ];

  @override
  Future<DayClosingState> dayClosing(DateTime date) async => DayClosingState.fromJson({
        'date': '2026-10-22',
        'closed': false,
        'can_close': true,
        'blocked_reason': null,
        'last_closed_on': '2026-10-21',
        'items': [_stockRows[0], _stockRows[1], _stockRows[3]],
        'closing': null,
        'can_cancel': false,
      });

  @override
  Future<List<Ingredient>> ingredientStock() async => [Ingredient.fromJson(_flour)];

  @override
  Future<Ingredient> ingredient(int id) async => Ingredient.fromJson({
        ..._flour,
        'purchases': [
          {'id': 1, 'purchased_on': '2026-10-15', 'quantity': 50, 'unit_price': 3300, 'total': 165000, 'supplier': 'Marché Analakely'},
        ],
        'usages': [
          {'id': 1, 'used_on': '2026-10-21', 'quantity': 6.5, 'note': null},
        ],
      });

  @override
  Future<ExpenseList> expenses(DateTime month) async => ExpenseList.fromJson({
        'data': [
          _electricity,
          {..._electricity, 'id': 2, 'category': 'rent', 'label': 'Loyer 10/2026', 'amount': 250000, 'paid_at': '2026-10-03', 'status': 'paid'},
          {..._electricity, 'id': 3, 'category': 'transport', 'label': 'Taxi-be', 'amount': 6000, 'period_month': null, 'due_date': null, 'status': 'due'},
        ],
        'summary': {'total': 318000, 'unpaid_total': 68000},
      });

  @override
  Future<EmployeeList> employees() async => EmployeeList.fromJson({
        'data': [
          _hery,
          {..._hery, 'id': 2, 'name': 'Voahangy', 'role': 'sales', 'left_on': '2026-09-30', 'active': false,
            'salary': {'as_of': '2026-10-22', 'accrued': 10, 'paid': 50010, 'balance': -50000, 'current_rate': 150000, 'unpaid_months': 0}},
        ],
        'total_due': 501935,
      });

  @override
  Future<Employee> employee(int id) async => Employee.fromJson({
        ..._hery,
        'salary_rates': [
          {'id': 1, 'monthly_amount': 180000, 'effective_from': '2026-04-01'},
          {'id': 2, 'monthly_amount': 200000, 'effective_from': '2026-10-01'},
        ],
        'payments': [
          {'id': 1, 'amount': 180000, 'paid_on': '2026-08-03', 'note': 'Salaire 07/2026'},
        ],
      });

  @override
  Future<Report> report(ReportPeriod period, DateTime date) async {
    final days = period == ReportPeriod.week ? 7 : 31;
    final start = period == ReportPeriod.week ? DateTime(2026, 10, 19) : DateTime(2026, 10);
    return Report.fromJson({
      'data': {
        'period': {'from': '2026-10-19', 'to': '2026-10-25', 'as_of': '2026-10-22', 'partial': true, 'type': period.name},
        'revenue': {'sales': 1059000, 'recovered': 9500, 'total': 1068500, 'by_category': {'bread': 570250, 'juice': 498250}},
        'charges': {
          'ingredients': 528500,
          'expenses': 6000,
          'monthly_expenses': 40258,
          'salaries': 45161,
          'total': 619919,
          'expenses_by_category': {'electricity': 8000, 'rent': 32258, 'transport': 6000, 'packaging': 0, 'other': 0},
          'salaries_by_employee': [
            {'employee_id': 1, 'name': 'Hery', 'amount': 25806},
            {'employee_id': 2, 'name': 'Voahangy', 'amount': 19355},
          ],
        },
        'profit': 448581,
        'top_products': [
          {'product_id': 1, 'name_fr': 'Baguette', 'name_mg': 'Mofo lava', 'format': 'piece', 'category': 'bread', 'quantity': 300, 'revenue': 240000},
          {'product_id': 4, 'name_fr': "Jus d'avocat", 'name_mg': 'Ranon-javoka', 'format': 'bottle', 'volume_ml': 500, 'category': 'juice', 'quantity': 40, 'revenue': 160000},
        ],
        'waste': {'quantity': 36, 'value': 28800, 'recovered': 9500},
        'series': [
          for (var i = 0; i < days; i++)
            {
              'date': '${start.year}-10-${(start.day + i).toString().padLeft(2, '0')}',
              'revenue': i < 4 ? 260000 + i * 10000 : 0,
              'charges': i < 4 ? 150000 : 0,
            },
        ],
      },
    });
  }

  @override
  Future<List<AppUser>> users() async => [
        AppUser.fromJson(_owner),
        AppUser.fromJson({'id': 2, 'name': 'Vendeur', 'phone': '0340000002', 'role': 'staff', 'active': false}),
      ];
}

Future<ProviderContainer> _startAsOwner(WidgetTester tester, String locale, {_FakeApi? api}) async {
  // Taille d'un téléphone courant : 360 × 800.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({
    'locale': locale,
    'auth_token': 'test-token',
    'auth_user': jsonEncode(_owner),
  });
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      bakeryApiProvider.overrideWithValue(api ?? _FakeApi()),
    ],
    retry: (retryCount, error) => null,
    child: const BoulangerieApp(),
  ));
  await tester.pumpAndSettle();

  return ProviderScope.containerOf(tester.element(find.byType(BoulangerieApp)));
}

/// Un « − » encore actif sur l'écran de clôture (le produit n'est pas encore compté à 0).
Finder _enabledMinus() => find.byWidgetPredicate(
      (widget) =>
          widget is IconButton &&
          widget.onPressed != null &&
          widget.icon is Icon &&
          (widget.icon as Icon).icon == Icons.remove_rounded,
    );

/// Fait défiler jusqu'au prochain « − » actif, puis le touche.
/// (scrollUntilVisible ne convient pas : avec `.first`, il échoue tant que la carte n'est pas encore construite.)
Future<void> _tapNextEnabledMinus(WidgetTester tester) async {
  for (var drags = 0; _enabledMinus().evaluate().isEmpty; drags++) {
    if (drags == 20) fail('Aucun « − » actif dans la liste de clôture');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(_enabledMinus().first);
  await tester.pumpAndSettle();
  await tester.tap(_enabledMinus().first);
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in ['mg', 'fr']) {
    testWidgets('tous les écrans s\'affichent sans erreur ni débordement ($locale, 360 × 800)', (tester) async {
      final container = await _startAsOwner(tester, locale);
      final router = container.read(routerProvider);

      expect(find.text(locale == 'mg' ? 'Salama Propriétaire' : 'Bonjour Propriétaire'), findsOneWidget);
      expect(tester.takeException(), isNull);

      const routes = [
        Routes.production,
        Routes.sale,
        Routes.closing,
        Routes.ingredients,
        '/ingredients/1',
        Routes.expenses,
        Routes.employees,
        '/employees/1',
        Routes.reports,
        Routes.products,
        Routes.users,
        Routes.settings,
      ];

      for (final route in routes) {
        unawaited(router.push(route));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Écran $route en $locale');

        // L'accueil est long : on fait défiler pour construire toutes les cartes.
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -1500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Écran $route en $locale (défilé)');

        router.pop();
        await tester.pumpAndSettle();
      }
    });
  }

  testWidgets('vente : toucher une tuile remplit le panier et affiche le total', (tester) async {
    final container = await _startAsOwner(tester, 'fr');
    unawaited(container.read(routerProvider).push(Routes.sale));
    await tester.pumpAndSettle();

    expect(find.text('Touchez un produit pour l\'ajouter'), findsOneWidget);
    await tester.tap(find.text('Baguette'));
    await tester.tap(find.text('Baguette'));
    await tester.pumpAndSettle();

    expect(find.text('1 600 Ar'), findsOneWidget);
    await tester.tap(find.text('Valider la vente'));
    await tester.pumpAndSettle();

    // Confirmation avant validation, avec le détail.
    expect(find.text('Valider cette vente ?'), findsOneWidget);
    expect(find.text('2 × Baguette'), findsOneWidget);
  });

  testWidgets('vente : même pain en deux tailles, chacune avec son prix', (tester) async {
    final container = await _startAsOwner(tester, 'fr');
    unawaited(container.read(routerProvider).push(Routes.sale));
    await tester.pumpAndSettle();

    final large = find.text('Pain au chocolat · grand');
    await tester.scrollUntilVisible(large, 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Pain au chocolat · petit'), findsOneWidget);
    expect(find.text('1 500 Ar'), findsOneWidget);

    await tester.tap(large);
    await tester.pumpAndSettle();

    // Le panier compte le prix du grand (1 500 Ar), pas celui du petit.
    expect(find.text('1 500 Ar'), findsNWidgets(2));
  });

  testWidgets('produit : un jus se vend à la bouteille, avec sa contenance et son prix', (tester) async {
    final api = _FakeApi();
    final container = await _startAsOwner(tester, 'fr', api: api);
    unawaited(container.read(routerProvider).push(Routes.products));
    await tester.pumpAndSettle();

    // Chaque bouteille se distingue par sa contenance.
    expect(find.text("Jus d'orange · ${formatVolume(1000)}"), findsOneWidget);
    expect(find.text("Jus d'avocat · ${formatVolume(500)}"), findsOneWidget);

    await tester.tap(find.text('Nouveau produit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jus'));
    await tester.pumpAndSettle();
    // Ni verre ni taille pour un jus : seulement la contenance.
    expect(find.text('verre'), findsNothing);
    expect(find.text('Taille unique'), findsNothing);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nom en malgache'), 'Ranom-boanio');
    await tester.enterText(find.widgetWithText(TextFormField, 'Nom en français'), 'Jus de coco');
    await tester.enterText(find.widgetWithText(TextFormField, 'Prix'), '3000');
    Future<void> tapVisible(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    // Sans contenance : refusé avant même d'appeler le serveur.
    await tapVisible(find.text('Enregistrer'));
    expect(find.text('Choisissez la contenance de la bouteille'), findsOneWidget);
    expect(api.savedProducts, isEmpty);

    await tapVisible(find.text(formatVolume(500)));
    await tapVisible(find.text('Enregistrer'));

    expect(api.savedProducts.single, containsPair('format', 'bottle'));
    expect(api.savedProducts.single, containsPair('volume_ml', 500));
    expect(api.savedProducts.single, containsPair('unit_price', 3000));
  });

  testWidgets('hors ligne : la vente est gardée, le stock en tient compte, puis elle part au retour du réseau',
      (tester) async {
    final api = _FakeApi()..offline = true;
    final container = await _startAsOwner(tester, 'fr', api: api);
    unawaited(container.read(routerProvider).push(Routes.sale));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Baguette'));
    await tester.tap(find.text('Baguette'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider la vente'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Valider la vente')));
    await tester.pumpAndSettle();

    // Rien n'est perdu : la vente attend sur le téléphone, et le stock affiché la déduit déjà.
    expect(find.textContaining('gardée sur le téléphone'), findsOneWidget);
    expect(container.read(outboxProvider), hasLength(1));
    expect(find.textContaining("1 en attente d'envoi"), findsOneWidget);
    expect(find.text('Dispo : 43'), findsOneWidget); // 45 - 2

    // Le réseau revient : la vente part, une seule fois, avec son identifiant.
    api.offline = false;
    await container.read(outboxProvider.notifier).flush();
    await tester.pumpAndSettle();

    expect(container.read(outboxProvider), isEmpty);
    expect(api.sent.single.kind, OutboxKind.sale);
    expect(api.sent.single.total, 1600);
    expect(find.textContaining("en attente d'envoi"), findsNothing);
  });

  testWidgets('hors ligne : la production est gardée aussi', (tester) async {
    final api = _FakeApi()..offline = true;
    final container = await _startAsOwner(tester, 'mg', api: api);
    unawaited(container.read(routerProvider).push(Routes.production));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Tehirizo ny famokarana'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Eny')));
    await tester.pumpAndSettle();

    expect(find.textContaining('voatahiry ao amin\'ny finday ny famokarana'), findsOneWidget);
    expect(container.read(outboxProvider).single.kind, OutboxKind.production);
  });

  testWidgets('la clôture attend que les ventes en attente soient envoyées', (tester) async {
    final api = _FakeApi()..offline = true;
    final container = await _startAsOwner(tester, 'fr', api: api);
    await container.read(outboxProvider.notifier).submit(OutboxOperation.create(
      OutboxKind.sale,
      [(productId: 1, quantity: 2, unitPrice: 800, label: 'Baguette')],
    ));
    unawaited(container.read(routerProvider).push(Routes.closing));
    await tester.pumpAndSettle();

    expect(find.textContaining('pas encore envoyée'), findsOneWidget);

    // Même tout compté, la validation reste bloquée.
    for (var i = 0; i < 3; i++) {
      await _tapNextEnabledMinus(tester);
    }
    expect(_enabledMinus(), findsNothing);
    final validate = find.widgetWithText(FilledButton, 'Valider la clôture');
    expect(tester.widget<FilledButton>(validate).onPressed, isNull);
  });

  testWidgets('clôture : validation possible seulement quand tout est compté, avec aperçu', (tester) async {
    final container = await _startAsOwner(tester, 'fr');
    unawaited(container.read(routerProvider).push(Routes.closing));
    await tester.pumpAndSettle();

    final validate = find.widgetWithText(FilledButton, 'Valider la clôture');
    expect(tester.widget<FilledButton>(validate).onPressed, isNull);
    expect(find.text('Comptez tous les produits pour valider'), findsOneWidget);

    // « − » sur un produit pas encore compté = il ne reste rien (le bouton se désactive ensuite à 0).
    for (var i = 0; i < 3; i++) {
      await _tapNextEnabledMinus(tester);
    }
    expect(_enabledMinus(), findsNothing);

    expect(tester.widget<FilledButton>(validate).onPressed, isNotNull);
    // Tout vendu : 45 × 800 + 30 × 3 000 + 8 × 4 000.
    expect(find.text('Vendu : 158 000 Ar'), findsOneWidget);
  });
}

