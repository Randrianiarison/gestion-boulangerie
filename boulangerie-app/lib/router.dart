import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/closing/closing_screen.dart';
import 'features/employees/employee_detail_screen.dart';
import 'features/employees/employees_screen.dart';
import 'features/expenses/expenses_screen.dart';
import 'features/home/home_screen.dart';
import 'features/ingredients/ingredient_detail_screen.dart';
import 'features/ingredients/ingredients_screen.dart';
import 'features/production/production_screen.dart';
import 'features/products/products_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/sales/sale_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/users/users_screen.dart';
import 'models/user.dart';

abstract final class Routes {
  static const login = '/login';
  static const home = '/';
  static const production = '/production';
  static const sale = '/sale';
  static const closing = '/closing';
  static const ingredients = '/ingredients';
  static const expenses = '/expenses';
  static const employees = '/employees';
  static const reports = '/reports';
  static const products = '/products';
  static const users = '/users';
  static const settings = '/settings';

  static String ingredient(int id) => '$ingredients/$id';

  static String employee(int id) => '$employees/$id';

  /// Salaires, dépenses, rapports, catalogue et comptes : owner uniquement.
  static const ownerOnly = [expenses, employees, reports, products, users];
}

final routerProvider = Provider<GoRouter>((ref) {
  // go_router relance `redirect` quand la session change (connexion, déconnexion, jeton expiré).
  final session = ValueNotifier<AppUser?>(ref.read(authProvider).user);
  ref.listen(authProvider, (_, next) => session.value = next.user);
  ref.onDispose(session.dispose);

  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: session,
    redirect: (context, state) {
      final user = session.value;
      final location = state.matchedLocation;

      if (user == null) return location == Routes.login ? null : Routes.login;
      if (location == Routes.login) return Routes.home;
      if (!user.isOwner && Routes.ownerOnly.any(location.startsWith)) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(path: Routes.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: Routes.home, builder: (context, state) => const HomeScreen()),
      GoRoute(path: Routes.production, builder: (context, state) => const ProductionScreen()),
      GoRoute(path: Routes.sale, builder: (context, state) => const SaleScreen()),
      GoRoute(path: Routes.closing, builder: (context, state) => const ClosingScreen()),
      GoRoute(
        path: Routes.ingredients,
        builder: (context, state) => const IngredientsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => IngredientDetailScreen(id: int.parse(state.pathParameters['id']!)),
          ),
        ],
      ),
      GoRoute(path: Routes.expenses, builder: (context, state) => const ExpensesScreen()),
      GoRoute(
        path: Routes.employees,
        builder: (context, state) => const EmployeesScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => EmployeeDetailScreen(id: int.parse(state.pathParameters['id']!)),
          ),
        ],
      ),
      GoRoute(path: Routes.reports, builder: (context, state) => const ReportsScreen()),
      GoRoute(path: Routes.products, builder: (context, state) => const ProductsScreen()),
      GoRoute(path: Routes.users, builder: (context, state) => const UsersScreen()),
      GoRoute(path: Routes.settings, builder: (context, state) => const SettingsScreen()),
    ],
  );
});
