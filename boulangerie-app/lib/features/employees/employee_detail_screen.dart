import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/labels.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../models/employee.dart';
import '../../widgets/async_view.dart';
import '../../widgets/cards.dart';
import '../../widgets/dialogs.dart';
import 'employee_forms.dart';
import 'employees_screen.dart';

/// Fiche employé : solde dû, payer, changer le salaire, historiques.
class EmployeeDetailScreen extends ConsumerWidget {
  const EmployeeDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final employee = ref.watch(employeeProvider(id));
    void refresh() => ref.invalidate(employeeProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text(employee.value?.name ?? l10n.employeesTitle),
        actions: [
          if (employee.value != null) ...[
            IconButton(
              tooltip: l10n.edit,
              icon: const Icon(Icons.edit_rounded),
              onPressed: () async {
                if (await showEmployeeSheet(context, employee: employee.value)) refresh();
              },
            ),
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _delete(context, ref, employee.value!),
            ),
          ],
        ],
      ),
      body: AsyncView(
        value: employee,
        onRetry: refresh,
        builder: (employee) => _Body(employee: employee, refresh: refresh),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Employee employee) async {
    final l10n = context.l10n;
    if (!await confirmDialog(context, title: l10n.deleteConfirm(employee.name), danger: true)) return;
    try {
      await ref.read(bakeryApiProvider).deleteEmployee(employee.id);
      if (!context.mounted) return;
      showSuccess(context, l10n.deleted);
      Navigator.pop(context);
    } on Object catch (error) {
      if (context.mounted) showError(context, error);
    }
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.employee, required this.refresh});

  final Employee employee;
  final VoidCallback refresh;

  Future<void> _deletePayment(BuildContext context, WidgetRef ref, SalaryPayment payment) async {
    final l10n = context.l10n;
    final label = '${formatMoney(payment.amount)} · ${context.dates.short(payment.paidOn)}';
    if (!await confirmDialog(context, title: l10n.deleteConfirm(label), danger: true)) return;
    try {
      await ref.read(bakeryApiProvider).deletePayment(payment.id);
      refresh();
    } on Object catch (error) {
      if (context.mounted) showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final dates = context.dates;
    final salary = employee.salary;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Text(
                [
                  l10n.employeeRoleLabel(employee.role),
                  '${l10n.hiredOn} : ${dates.short(employee.hiredOn)}',
                  if (employee.leftOn != null) l10n.leftCompany(dates.short(employee.leftOn!)),
                ].join(' · '),
                textAlign: TextAlign.center,
              ),
              if (salary != null) ...[
                const SizedBox(height: 12),
                SalaryBalanceText(summary: salary, large: true),
                const Divider(height: 32),
                AmountRow(label: l10n.accrued, amount: salary.accrued),
                AmountRow(label: l10n.paid, amount: salary.paid),
                AmountRow(label: l10n.currentSalary, amount: salary.currentRate, bold: true),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: () async {
                if (await showPaymentSheet(context, employee)) refresh();
              },
              icon: const Icon(Icons.payments_rounded),
              label: Text(l10n.pay),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                if (await showSalarySheet(context, employee)) refresh();
              },
              icon: const Icon(Icons.trending_up_rounded),
              label: Text(l10n.changeSalary, overflow: TextOverflow.ellipsis),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.paymentHistory,
          icon: Icons.history_rounded,
          child: employee.payments.isEmpty
              ? Text(l10n.noPayments)
              : Column(children: [
                  for (final payment in employee.payments)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.payments_outlined, color: AppColors.success),
                      title: Text(formatMoney(payment.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text([dates.short(payment.paidOn), ?payment.note].join(' · ')),
                      trailing: IconButton(
                        tooltip: l10n.delete,
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () => _deletePayment(context, ref, payment),
                      ),
                    ),
                ]),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.salaryHistory,
          icon: Icons.trending_up_rounded,
          child: Column(children: [
            for (final rate in employee.rates.reversed)
              AmountRow(label: '${l10n.effectiveFrom} ${dates.short(rate.effectiveFrom)}', amount: rate.monthlyAmount),
          ]),
        ),
      ],
    );
  }
}
