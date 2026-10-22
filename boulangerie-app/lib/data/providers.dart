import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/settings.dart';
import '../features/auth/auth_controller.dart';
import '../models/dashboard.dart';
import '../models/employee.dart';
import '../models/expense.dart';
import '../models/ingredient.dart';
import '../models/report.dart';
import '../models/stock.dart';
import '../models/user.dart';
import 'bakery_api.dart';

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    baseUrl: () => ref.read(apiUrlProvider),
    token: () => ref.read(authProvider).token,
    languageCode: () => ref.read(localeProvider).languageCode,
    // Jeton refusé (compte désactivé, PIN changé) : retour à l'écran de connexion.
    onUnauthorized: () => ref.read(authProvider.notifier).expire(),
  ),
);

final bakeryApiProvider = Provider<BakeryApi>((ref) => BakeryApi(ref.watch(apiClientProvider)));

final dashboardProvider = FutureProvider.autoDispose<Dashboard>((ref) => ref.watch(bakeryApiProvider).dashboard());

final activeProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) => ref.watch(bakeryApiProvider).products(activeOnly: true));

final allProductsProvider = FutureProvider.autoDispose<List<Product>>((ref) => ref.watch(bakeryApiProvider).products());

final stockProvider = FutureProvider.autoDispose<List<StockRow>>((ref) => ref.watch(bakeryApiProvider).stock());

final productionTodayProvider =
    FutureProvider.autoDispose<List<StockLot>>((ref) => ref.watch(bakeryApiProvider).productionOn(today()));

final dayClosingProvider = FutureProvider.autoDispose.family<DayClosingState, DateTime>(
  (ref, date) => ref.watch(bakeryApiProvider).dayClosing(date),
);

final ingredientStockProvider =
    FutureProvider.autoDispose<List<Ingredient>>((ref) => ref.watch(bakeryApiProvider).ingredientStock());

final ingredientProvider = FutureProvider.autoDispose.family<Ingredient, int>(
  (ref, id) => ref.watch(bakeryApiProvider).ingredient(id),
);

final expensesProvider = FutureProvider.autoDispose.family<ExpenseList, DateTime>(
  (ref, month) => ref.watch(bakeryApiProvider).expenses(month),
);

final employeesProvider = FutureProvider.autoDispose<EmployeeList>((ref) => ref.watch(bakeryApiProvider).employees());

final employeeProvider = FutureProvider.autoDispose.family<Employee, int>(
  (ref, id) => ref.watch(bakeryApiProvider).employee(id),
);

final reportProvider = FutureProvider.autoDispose.family<Report, (ReportPeriod, DateTime)>(
  (ref, query) => ref.watch(bakeryApiProvider).report(query.$1, query.$2),
);

final usersProvider = FutureProvider.autoDispose<List<AppUser>>((ref) => ref.watch(bakeryApiProvider).users());

/// Après une vente, une production ou une clôture : tout ce qui affiche du stock est relu.
void invalidateStock(WidgetRef ref) {
  ref
    ..invalidate(stockProvider)
    ..invalidate(productionTodayProvider)
    ..invalidate(dayClosingProvider)
    ..invalidate(dashboardProvider);
}
