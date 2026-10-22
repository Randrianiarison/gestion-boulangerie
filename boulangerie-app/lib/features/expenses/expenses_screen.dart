import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/labels.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../models/expense.dart';
import '../../widgets/async_view.dart';
import '../../widgets/cards.dart';
import '../../widgets/dialogs.dart';
import 'expense_form.dart';

IconData expenseIcon(ExpenseCategory category) => switch (category) {
      ExpenseCategory.electricity => Icons.bolt_rounded,
      ExpenseCategory.rent => Icons.home_rounded,
      ExpenseCategory.transport => Icons.local_shipping_rounded,
      ExpenseCategory.packaging => Icons.inventory_2_rounded,
      ExpenseCategory.other => Icons.receipt_rounded,
    };

Color expenseStatusColor(ExpenseStatus status) => switch (status) {
      ExpenseStatus.paid => AppColors.success,
      ExpenseStatus.due => AppColors.warning,
      ExpenseStatus.overdue => AppColors.danger,
    };

/// Dépenses du mois et factures (électricité, loyer) avec leur statut payé / à payer.
class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  DateTime _month = DateTime(today().year, today().month);

  void _refresh() => ref.invalidate(expensesProvider(_month));

  Future<void> _actions(Expense expense) async {
    final l10n = context.l10n;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (expense.paidAt == null)
            ListTile(
              leading: const Icon(Icons.check_circle_rounded, color: AppColors.success),
              title: Text(l10n.markPaid),
              onTap: () => Navigator.pop(context, 'pay'),
            ),
          ListTile(
            leading: const Icon(Icons.edit_rounded),
            title: Text(l10n.edit),
            onTap: () => Navigator.pop(context, 'edit'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            title: Text(l10n.delete),
            onTap: () => Navigator.pop(context, 'delete'),
          ),
        ]),
      ),
    );
    if (action == null || !mounted) return;

    final api = ref.read(bakeryApiProvider);
    try {
      switch (action) {
        case 'pay':
          if (!await confirmDialog(context, title: l10n.markPaidConfirm(expense.label))) return;
          await api.payExpense(expense.id);
          if (mounted) showSuccess(context, l10n.statusPaid);
        case 'edit':
          if (!await showExpenseSheet(context, expense: expense)) return;
        case 'delete':
          if (!await confirmDialog(context, title: l10n.deleteConfirm(expense.label), danger: true)) return;
          await api.deleteExpense(expense.id);
          if (mounted) showSuccess(context, l10n.deleted);
      }
      _refresh();
      ref.invalidate(dashboardProvider);
    } on Object catch (error) {
      if (mounted) showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final expenses = ref.watch(expensesProvider(_month));
    final now = today();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.expensesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (await showExpenseSheet(context)) _refresh();
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.expenseNew),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: PeriodNavigator(
            label: context.dates.monthYear(_month),
            onPrevious: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
            onNext: _month.isBefore(DateTime(now.year, now.month + 1))
                ? () => setState(() => _month = DateTime(_month.year, _month.month + 1))
                : null,
          ),
        ),
        Expanded(
          child: AsyncView(
            value: expenses,
            onRetry: _refresh,
            builder: (list) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      AmountRow(label: l10n.monthTotal, amount: list.total, bold: true),
                      AmountRow(
                        label: l10n.unpaidTotal,
                        amount: list.unpaidTotal,
                        color: list.unpaidTotal > 0 ? AppColors.danger : AppColors.success,
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                if (list.expenses.isEmpty)
                  Padding(padding: const EdgeInsets.all(24), child: Text(l10n.noExpenses, textAlign: TextAlign.center)),
                for (final expense in list.expenses)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ExpenseTile(expense: expense, onTap: () => _actions(expense)),
                  ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense, required this.onTap});

  final Expense expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dates = context.dates;
    final color = expenseStatusColor(expense.status);
    final details = [
      l10n.expenseCategoryLabel(expense.category),
      if (expense.periodMonth != null) dates.monthYear(expense.periodMonth!),
      if (expense.paidAt != null)
        l10n.paidOn(dates.short(expense.paidAt!))
      else if (expense.dueDate != null)
        l10n.dueOn(dates.short(expense.dueDate!)),
    ];

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(expenseIcon(expense.category), color: color),
        ),
        title: Text(expense.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(details.join(' · ')),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(formatMoney(expense.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            StatusChip(label: l10n.expenseStatusLabel(expense.status), color: color),
          ],
        ),
      ),
    );
  }
}
