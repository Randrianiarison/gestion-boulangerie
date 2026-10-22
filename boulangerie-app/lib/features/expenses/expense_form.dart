import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/labels.dart';
import '../../data/providers.dart';
import '../../models/expense.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/fields.dart';
import 'expenses_screen.dart';

/// Nouvelle dépense ou modification. Électricité et loyer demandent le mois concerné.
Future<bool> showExpenseSheet(BuildContext context, {Expense? expense}) async {
  final saved = await showFormSheet<bool>(
    context,
    title: expense?.label ?? context.l10n.expenseNew,
    child: _ExpenseForm(expense: expense),
  );
  return saved ?? false;
}

class _ExpenseForm extends ConsumerStatefulWidget {
  const _ExpenseForm({this.expense});

  final Expense? expense;

  @override
  ConsumerState<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<_ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final _label = TextEditingController(text: widget.expense?.label);
  late final _amount = TextEditingController(text: widget.expense?.amount.toString());
  late ExpenseCategory _category = widget.expense?.category ?? ExpenseCategory.electricity;
  late DateTime _month = widget.expense?.periodMonth ?? DateTime(today().year, today().month);
  late DateTime _expenseDate = widget.expense?.expenseDate ?? today();
  late DateTime? _dueDate = widget.expense?.dueDate;
  late DateTime? _paidAt = widget.expense?.paidAt;
  bool _saving = false;

  @override
  void dispose() {
    _label.dispose();
    _amount.dispose();
    super.dispose();
  }

  /// Mois proposés : les 12 derniers et le suivant.
  List<DateTime> get _months {
    final now = today();
    return [for (var offset = 1; offset >= -12; offset--) DateTime(now.year, now.month + offset)];
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final label = _label.text.trim().isEmpty
        ? '${l10n.expenseCategoryLabel(_category)} ${context.dates.monthYear(_month)}'
        : _label.text.trim();

    setState(() => _saving = true);
    try {
      await ref.read(bakeryApiProvider).saveExpense(widget.expense?.id, {
        'category': _category.name,
        'label': label,
        'amount': parseInt(_amount.text),
        'expense_date': isoDate(_expenseDate),
        'period_month': _category.isMonthly ? isoMonth(_month) : null,
        'due_date': _dueDate == null ? null : isoDate(_dueDate!),
        'paid_at': _paidAt == null ? null : isoDate(_paidAt!),
      });
      if (!mounted) return;
      showSuccess(context, l10n.expenseSaved);
      ref.invalidate(dashboardProvider);
      Navigator.pop(context, true);
    } on Object catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final months = _months;
    if (!months.contains(_month)) months.add(_month);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.expenseCategory),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final category in ExpenseCategory.values)
              ChoiceChip(
                avatar: Icon(expenseIcon(category)),
                label: Text(l10n.expenseCategoryLabel(category)),
                selected: _category == category,
                onSelected: (_) => setState(() => _category = category),
              ),
          ]),
          const SizedBox(height: 16),
          TextFormField(controller: _label, decoration: InputDecoration(labelText: l10n.expenseLabel)),
          const SizedBox(height: 12),
          AmountField(controller: _amount, label: l10n.amount),
          const SizedBox(height: 12),
          if (_category.isMonthly) ...[
            DropdownButtonFormField<DateTime>(
              initialValue: _month,
              decoration: InputDecoration(labelText: l10n.expenseMonth, prefixIcon: const Icon(Icons.calendar_month_rounded)),
              items: [for (final month in months) DropdownMenuItem(value: month, child: Text(context.dates.monthYear(month)))],
              onChanged: (month) => setState(() => _month = month ?? _month),
            ),
            const SizedBox(height: 12),
          ] else ...[
            DateField(label: l10n.date, value: _expenseDate, onChanged: (date) => setState(() => _expenseDate = date ?? today())),
            const SizedBox(height: 12),
          ],
          DateField(label: l10n.dueDate, value: _dueDate, clearable: true, onChanged: (date) => setState(() => _dueDate = date)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.alreadyPaid, style: const TextStyle(fontSize: 17)),
            value: _paidAt != null,
            onChanged: (paid) => setState(() => _paidAt = paid ? today() : null),
          ),
          if (_paidAt != null)
            DateField(
              label: l10n.paymentDate,
              value: _paidAt,
              lastDate: today(),
              onChanged: (date) => setState(() => _paidAt = date ?? today()),
            ),
          const SizedBox(height: 20),
          SheetActions(onSave: _save, saving: _saving),
        ],
      ),
    );
  }
}
