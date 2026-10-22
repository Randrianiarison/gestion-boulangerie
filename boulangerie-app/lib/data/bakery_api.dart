import '../core/api_client.dart';
import '../core/format.dart';
import '../models/dashboard.dart';
import '../models/employee.dart';
import '../models/expense.dart';
import '../models/ingredient.dart';
import '../models/json.dart';
import '../models/report.dart';
import '../models/stock.dart';
import '../models/user.dart';

/// Une ligne « produit + quantité » (production, vente au comptoir).
typedef QuantityLine = ({int productId, int quantity});

/// Une ligne de comptage du soir.
typedef CountLine = ({int productId, int remaining, int? recoveredAmount});

/// Appels typés à l'API de la boulangerie.
class BakeryApi {
  const BakeryApi(this._client);

  final ApiClient _client;

  // Auth -------------------------------------------------------------------

  Future<({String token, AppUser user})> login(String phone, String pin) async {
    final data = asJson((await _client.post('/login', {'phone': phone, 'pin': pin, 'device_name': 'mobile'}))['data']);
    return (token: data['token'] as String, user: AppUser.fromJson(asJson(data['user'])));
  }

  Future<void> logout() => _client.post('/logout');

  Future<AppUser> me() async => AppUser.fromJson(asJson((await _client.get('/me'))['data']));

  // Tableau de bord, produits, stock ---------------------------------------

  Future<Dashboard> dashboard() async => Dashboard.fromJson(await _client.get('/dashboard'));

  Future<List<Product>> products({bool activeOnly = false}) async =>
      asList((await _client.get('/products', query: {'active': activeOnly ? 1 : null}))['data'], Product.fromJson);

  Future<void> saveProduct(int? id, Json data) =>
      id == null ? _client.post('/products', data) : _client.put('/products/$id', data);

  Future<List<StockRow>> stock() async => asList((await _client.get('/stock'))['data'], StockRow.fromJson);

  // Production, ventes, clôture, invendus ----------------------------------

  Future<List<StockLot>> productionOn(DateTime date) async =>
      asList((await _client.get('/production', query: {'date': isoDate(date)}))['data'], StockLot.fromJson);

  Future<void> produce(List<QuantityLine> lines) => _client.post('/production', {
        'items': [for (final line in lines) {'product_id': line.productId, 'quantity': line.quantity}],
      });

  Future<void> deleteLot(int lotId) => _client.delete('/production/$lotId');

  /// Renvoie le total encaissé.
  Future<int> sell(List<QuantityLine> lines) async {
    final response = await _client.post('/sales', {
      'items': [for (final line in lines) {'product_id': line.productId, 'quantity': line.quantity}],
    });
    return asInt(response['total']);
  }

  Future<DayClosingState> dayClosing(DateTime date) async =>
      DayClosingState.fromJson(asJson((await _client.get('/day-closing/${isoDate(date)}'))['data']));

  Future<void> closeDay(DateTime date, List<CountLine> lines) => _client.post('/day-closing/${isoDate(date)}', {
        'items': [
          for (final line in lines)
            {
              'product_id': line.productId,
              'remaining': line.remaining,
              if (line.recoveredAmount != null) 'recovered_amount': line.recoveredAmount,
            },
        ],
      });

  Future<void> cancelClosing(DateTime date) => _client.delete('/day-closing/${isoDate(date)}');

  Future<void> declareWaste({
    required int productId,
    required int quantity,
    required WasteReason reason,
    String? note,
  }) =>
      _client.post('/waste-records', {
        'product_id': productId,
        'quantity': quantity,
        'reason': reason.name,
        if (note != null && note.isNotEmpty) 'note': note,
      });

  // Ingrédients ------------------------------------------------------------

  Future<List<Ingredient>> ingredientStock() async =>
      asList((await _client.get('/ingredients/stock'))['data'], Ingredient.fromJson);

  Future<Ingredient> ingredient(int id) async =>
      Ingredient.fromJson(asJson((await _client.get('/ingredients/$id'))['data']));

  Future<void> saveIngredient(int? id, Json data) =>
      id == null ? _client.post('/ingredients', data) : _client.put('/ingredients/$id', data);

  Future<void> deleteIngredient(int id) => _client.delete('/ingredients/$id');

  /// Quantité + soit le prix unitaire, soit le total payé.
  Future<void> purchaseIngredient({
    required int ingredientId,
    required double quantity,
    int? unitPrice,
    int? total,
    required DateTime date,
    String? supplier,
  }) =>
      _client.post('/ingredient-purchases', {
        'ingredient_id': ingredientId,
        'quantity': quantity,
        'unit_price': ?unitPrice,
        'total': ?total,
        'purchased_on': isoDate(date),
        if (supplier != null && supplier.isNotEmpty) 'supplier': supplier,
      });

  Future<void> useIngredient({required int ingredientId, required double quantity, required DateTime date}) =>
      _client.post('/ingredient-usages', {'ingredient_id': ingredientId, 'quantity': quantity, 'used_on': isoDate(date)});

  // Dépenses (owner) -------------------------------------------------------

  Future<ExpenseList> expenses(DateTime month) async =>
      ExpenseList.fromJson(await _client.get('/expenses', query: {'month': isoMonth(month)}));

  Future<void> saveExpense(int? id, Json data) =>
      id == null ? _client.post('/expenses', data) : _client.put('/expenses/$id', data);

  Future<void> payExpense(int id) => _client.post('/expenses/$id/pay');

  Future<void> deleteExpense(int id) => _client.delete('/expenses/$id');

  // Employés et salaires (owner) -------------------------------------------

  Future<EmployeeList> employees() async => EmployeeList.fromJson(await _client.get('/employees'));

  Future<Employee> employee(int id) async => Employee.fromJson(asJson((await _client.get('/employees/$id'))['data']));

  Future<void> saveEmployee(int? id, Json data) =>
      id == null ? _client.post('/employees', data) : _client.put('/employees/$id', data);

  Future<void> deleteEmployee(int id) => _client.delete('/employees/$id');

  Future<void> paySalary(int employeeId, {required int amount, required DateTime date, String? note}) =>
      _client.post('/employees/$employeeId/payments', {
        'amount': amount,
        'paid_on': isoDate(date),
        if (note != null && note.isNotEmpty) 'note': note,
      });

  Future<void> deletePayment(int paymentId) => _client.delete('/salary-payments/$paymentId');

  Future<void> changeSalary(int employeeId, {required int monthlyAmount, required DateTime from}) =>
      _client.post('/employees/$employeeId/salary-rates', {'monthly_amount': monthlyAmount, 'effective_from': isoDate(from)});

  // Rapports (owner) -------------------------------------------------------

  Future<Report> report(ReportPeriod period, DateTime date) async =>
      Report.fromJson(await _client.get('/reports/summary', query: {'period': period.name, 'date': isoDate(date)}));

  // Comptes (owner) --------------------------------------------------------

  Future<List<AppUser>> users() async => asList((await _client.get('/users'))['data'], AppUser.fromJson);

  Future<void> saveUser(int? id, Json data) => id == null ? _client.post('/users', data) : _client.put('/users/$id', data);
}
