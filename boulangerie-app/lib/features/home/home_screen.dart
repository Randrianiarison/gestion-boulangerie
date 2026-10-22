import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/labels.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../models/dashboard.dart';
import '../../models/expense.dart';
import '../../router.dart';
import '../../widgets/async_view.dart';
import '../../widgets/cards.dart';
import '../auth/auth_controller.dart';

/// Tableau de bord : recettes du jour, accès rapides, alertes, stock.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(authProvider).user;
    final dashboard = ref.watch(dashboardProvider);

    // Au retour d'un écran (vente, clôture…), les chiffres sont relus.
    Future<void> open(String route) async {
      await context.push(route);
      ref.invalidate(dashboardProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(user == null ? l10n.homeTitle : l10n.greeting(user.name)),
        actions: [
          IconButton(
            tooltip: l10n.settings,
            iconSize: 30,
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            switch (dashboard) {
              AsyncData(:final value) => _RevenueCard(revenue: value.revenueToday),
              AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(dashboardProvider)),
              _ => const LinearProgressIndicator(),
            },
            const SizedBox(height: 16),
            _MenuGrid(isOwner: user?.isOwner ?? false, open: open),
            if (dashboard case AsyncData(:final value)) ...[
              const SizedBox(height: 16),
              _AlertsCard(dashboard: value, open: open),
              const SizedBox(height: 16),
              _StockCard(dashboard: value),
            ],
          ],
        ),
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.revenue});

  final Revenue revenue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.revenueToday, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                formatMoney(revenue.total),
                style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              StatusChip(
                icon: Icons.bakery_dining_rounded,
                label: '${l10n.bread} : ${formatMoney(revenue.byCategory['bread'] ?? 0)}',
                color: AppColors.bread,
              ),
              StatusChip(
                icon: Icons.local_drink_rounded,
                label: '${l10n.juice} : ${formatMoney(revenue.byCategory['juice'] ?? 0)}',
                color: AppColors.juice,
              ),
              if (revenue.recovered > 0)
                StatusChip(
                  icon: Icons.recycling_rounded,
                  label: '${l10n.recovered} : ${formatMoney(revenue.recovered)}',
                  color: AppColors.info,
                ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({required this.isOwner, required this.open});

  final bool isOwner;
  final Future<void> Function(String route) open;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tiles = [
      (Icons.bakery_dining_rounded, l10n.menuProduction, AppColors.bread, Routes.production),
      (Icons.point_of_sale_rounded, l10n.menuSale, AppColors.success, Routes.sale),
      (Icons.nightlight_round, l10n.menuClosing, const Color(0xFF4527A0), Routes.closing),
      (Icons.inventory_2_rounded, l10n.menuIngredients, const Color(0xFF6D4C41), Routes.ingredients),
      if (isOwner) ...[
        (Icons.receipt_long_rounded, l10n.menuExpenses, AppColors.warning, Routes.expenses),
        (Icons.groups_rounded, l10n.menuEmployees, AppColors.info, Routes.employees),
        (Icons.bar_chart_rounded, l10n.menuReports, const Color(0xFF00838F), Routes.reports),
        (Icons.sell_rounded, l10n.menuProducts, const Color(0xFF8E24AA), Routes.products),
        (Icons.manage_accounts_rounded, l10n.menuUsers, const Color(0xFF546E7A), Routes.users),
      ],
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth > 600 ? 4 : 2;
      return GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.15,
        children: [
          for (final (icon, label, color, route) in tiles)
            BigTile(icon: icon, label: label, color: color, onTap: () => open(route)),
        ],
      );
    });
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({required this.dashboard, required this.open});

  final Dashboard dashboard;
  final Future<void> Function(String route) open;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = context.lang;
    final bills = dashboard.billsDue ?? const <Expense>[];
    final salariesDue = dashboard.salariesDueTotal ?? 0;

    final alerts = <Widget>[
      if (!dashboard.closedToday)
        _AlertTile(
          icon: Icons.nightlight_round,
          color: const Color(0xFF4527A0),
          title: l10n.closingNotDone,
          onTap: () => open(Routes.closing),
        ),
      if (dashboard.ingredientAlerts.isNotEmpty)
        _AlertTile(
          icon: Icons.warning_amber_rounded,
          color: AppColors.warning,
          title: l10n.lowIngredients(dashboard.ingredientAlerts.map((i) => i.name(lang)).join(', ')),
          onTap: () => open(Routes.ingredients),
        ),
      for (final bill in bills)
        _AlertTile(
          icon: bill.category == ExpenseCategory.electricity ? Icons.bolt_rounded : Icons.receipt_long_rounded,
          color: bill.status == ExpenseStatus.overdue ? AppColors.danger : AppColors.warning,
          title: '${bill.label} · ${formatMoney(bill.amount)}',
          subtitle: bill.dueDate == null
              ? l10n.expenseStatusLabel(bill.status)
              : '${l10n.expenseStatusLabel(bill.status)} · ${l10n.dueOn(context.dates.short(bill.dueDate!))}',
          onTap: () => open(Routes.expenses),
        ),
      if (salariesDue > 0)
        _AlertTile(
          icon: Icons.groups_rounded,
          color: AppColors.info,
          title: '${l10n.salariesDue} : ${formatMoney(salariesDue)}',
          onTap: () => open(Routes.employees),
        ),
    ];

    return SectionCard(
      title: l10n.alerts,
      icon: Icons.notifications_active_rounded,
      child: alerts.isEmpty
          ? Row(children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.success),
              const SizedBox(width: 8),
              Text(l10n.noAlerts),
            ])
          : Column(children: alerts),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.icon, required this.color, required this.title, required this.onTap, this.subtitle});

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _StockCard extends StatelessWidget {
  const _StockCard({required this.dashboard});

  final Dashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = dashboard.stock.where((row) => row.product.active || row.available > 0).toList();

    return SectionCard(
      title: l10n.stockToday,
      icon: Icons.storefront_rounded,
      child: rows.isEmpty
          ? Text(l10n.noData)
          : Column(children: [
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Expanded(child: Text(row.product.label(context), style: const TextStyle(fontSize: 16))),
                    row.available == 0
                        ? StatusChip(label: l10n.outOfStock, color: AppColors.danger)
                        : CountText(row.available, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ]),
                ),
            ]),
    );
  }
}
