import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/labels.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../models/employee.dart';
import '../../router.dart';
import '../../widgets/async_view.dart';
import '../../widgets/cards.dart';
import 'employee_forms.dart';

/// « 2,5 » mois.
String formatMonths(double months) => formatQuantity(months, decimals: 1);

/// Solde dû par employé : rouge = à payer, bleu = avance, vert = à jour.
class SalaryBalanceText extends StatelessWidget {
  const SalaryBalanceText({super.key, required this.summary, this.large = false});

  final SalarySummary summary;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final balance = summary.balance;
    final (label, color) = switch (balance) {
      > 0 => (l10n.balanceDue, AppColors.danger),
      < 0 => (l10n.advance, AppColors.info),
      _ => (l10n.upToDate, AppColors.success),
    };
    final amountStyle = (large ? Theme.of(context).textTheme.headlineMedium : Theme.of(context).textTheme.titleMedium)
        ?.copyWith(color: color, fontWeight: FontWeight.bold);

    return Column(
      crossAxisAlignment: large ? CrossAxisAlignment.center : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, textAlign: large ? TextAlign.center : TextAlign.end, style: TextStyle(color: color)),
        if (balance != 0)
          FittedBox(fit: BoxFit.scaleDown, child: Text(formatMoney(balance.abs()), style: amountStyle)),
        if (balance > 0 && summary.unpaidMonths != null)
          StatusChip(label: l10n.unpaidMonths(formatMonths(summary.unpaidMonths!)), color: color),
      ],
    );
  }
}

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final employees = ref.watch(employeesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.employeesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (await showEmployeeSheet(context)) ref.invalidate(employeesProvider);
        },
        icon: const Icon(Icons.person_add_rounded),
        label: Text(l10n.employeeNew),
      ),
      body: AsyncView(
        value: employees,
        onRetry: () => ref.invalidate(employeesProvider),
        builder: (list) => RefreshIndicator(
          onRefresh: () => ref.refresh(employeesProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Card(
                color: (list.totalDue > 0 ? AppColors.danger : AppColors.success).withValues(alpha: 0.12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AmountRow(label: l10n.totalDue, amount: list.totalDue, bold: true),
                ),
              ),
              const SizedBox(height: 12),
              for (final employee in list.employees)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _EmployeeTile(employee: employee),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeeTile extends ConsumerWidget {
  const _EmployeeTile({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final subtitle = [
      l10n.employeeRoleLabel(employee.role),
      if (employee.leftOn != null) l10n.leftCompany(context.dates.short(employee.leftOn!)),
    ].join(' · ');

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await context.push(Routes.employee(employee.id));
          ref.invalidate(employeesProvider);
        },
        child: Opacity(
          opacity: employee.active ? 1 : 0.6,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              CircleAvatar(
                radius: 26,
                child: Text(employee.name.characters.first.toUpperCase(), style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(employee.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(subtitle),
                ]),
              ),
              if (employee.salary != null) Flexible(child: SalaryBalanceText(summary: employee.salary!)),
            ]),
          ),
        ),
      ),
    );
  }
}
