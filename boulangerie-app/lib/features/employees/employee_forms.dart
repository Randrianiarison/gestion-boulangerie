import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/labels.dart';
import '../../data/providers.dart';
import '../../models/employee.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/fields.dart';

/// Nouvel employé (avec son salaire de départ) ou modification (dont la date de départ).
Future<bool> showEmployeeSheet(BuildContext context, {Employee? employee}) async {
  final saved = await showFormSheet<bool>(
    context,
    title: employee?.name ?? context.l10n.employeeNew,
    child: _EmployeeForm(employee: employee),
  );
  return saved ?? false;
}

/// Paiement libre : un mois, plusieurs mois d'un coup, ou une avance.
Future<bool> showPaymentSheet(BuildContext context, Employee employee) async {
  final saved = await showFormSheet<bool>(
    context,
    title: context.l10n.payTitle(employee.name),
    child: _PaymentForm(employee: employee),
  );
  return saved ?? false;
}

Future<bool> showSalarySheet(BuildContext context, Employee employee) async {
  final saved = await showFormSheet<bool>(
    context,
    title: context.l10n.changeSalary,
    child: _SalaryForm(employee: employee),
  );
  return saved ?? false;
}

class _EmployeeForm extends ConsumerStatefulWidget {
  const _EmployeeForm({this.employee});

  final Employee? employee;

  @override
  ConsumerState<_EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends ConsumerState<_EmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.employee?.name);
  late final _phone = TextEditingController(text: widget.employee?.phone);
  final _salary = TextEditingController();
  late EmployeeRole _role = widget.employee?.role ?? EmployeeRole.preparation;
  late DateTime _hiredOn = widget.employee?.hiredOn ?? today();
  late DateTime? _leftOn = widget.employee?.leftOn;
  bool _saving = false;

  bool get _creating => widget.employee == null;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _salary.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(bakeryApiProvider).saveEmployee(widget.employee?.id, {
        'name': _name.text.trim(),
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'role': _role.name,
        'hired_on': isoDate(_hiredOn),
        if (_creating) 'monthly_amount': parseInt(_salary.text) else 'left_on': _leftOn == null ? null : isoDate(_leftOn!),
      });
      if (!mounted) return;
      showSuccess(context, context.l10n.saved);
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            decoration: InputDecoration(labelText: l10n.employeeName),
            validator: (text) => (text ?? '').trim().isEmpty ? l10n.fieldRequired : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: l10n.employeePhone),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<EmployeeRole>(
            initialValue: _role,
            decoration: InputDecoration(labelText: l10n.employeeRole),
            items: [for (final role in EmployeeRole.values) DropdownMenuItem(value: role, child: Text(l10n.employeeRoleLabel(role)))],
            onChanged: (role) => setState(() => _role = role ?? _role),
          ),
          const SizedBox(height: 12),
          DateField(label: l10n.hiredOn, value: _hiredOn, onChanged: (date) => setState(() => _hiredOn = date ?? _hiredOn)),
          const SizedBox(height: 12),
          if (_creating)
            AmountField(controller: _salary, label: l10n.monthlySalary)
          else
            DateField(
              label: l10n.leftOn,
              value: _leftOn,
              clearable: true,
              firstDate: _hiredOn,
              onChanged: (date) => setState(() => _leftOn = date),
            ),
          const SizedBox(height: 20),
          SheetActions(onSave: _save, saving: _saving),
        ],
      ),
    );
  }
}

class _PaymentForm extends ConsumerStatefulWidget {
  const _PaymentForm({required this.employee});

  final Employee employee;

  @override
  ConsumerState<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends ConsumerState<_PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  // Proposé : tout ce qui est dû. On peut payer moins (un seul mois) ou plus (avance).
  late final _amount = TextEditingController(
    text: (widget.employee.salary?.balance ?? 0) > 0 ? widget.employee.salary!.balance.toString() : '',
  );
  final _note = TextEditingController();
  DateTime _date = today();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final amount = parseInt(_amount.text)!;

    final confirmed = await confirmDialog(
      context,
      title: l10n.payTitle(widget.employee.name),
      content: Text(formatMoney(amount), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      confirmLabel: l10n.pay,
    );
    if (!confirmed || !mounted) return;

    setState(() => _saving = true);
    try {
      await ref.read(bakeryApiProvider).paySalary(widget.employee.id, amount: amount, date: _date, note: _note.text.trim());
      if (!mounted) return;
      showSuccess(context, l10n.paymentSaved);
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AmountField(controller: _amount, label: l10n.amount, autofocus: true),
          const SizedBox(height: 12),
          DateField(label: l10n.paymentDate, value: _date, lastDate: today(), onChanged: (date) => setState(() => _date = date ?? today())),
          const SizedBox(height: 12),
          TextFormField(controller: _note, decoration: InputDecoration(labelText: l10n.note)),
          const SizedBox(height: 20),
          SheetActions(onSave: _save, saving: _saving, saveLabel: l10n.pay),
        ],
      ),
    );
  }
}

class _SalaryForm extends ConsumerStatefulWidget {
  const _SalaryForm({required this.employee});

  final Employee employee;

  @override
  ConsumerState<_SalaryForm> createState() => _SalaryFormState();
}

class _SalaryFormState extends ConsumerState<_SalaryForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  // Par défaut, le 1er du mois prochain.
  DateTime _from = DateTime(today().year, today().month + 1);
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(bakeryApiProvider).changeSalary(widget.employee.id, monthlyAmount: parseInt(_amount.text)!, from: _from);
      if (!mounted) return;
      showSuccess(context, context.l10n.salaryChanged);
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
    final current = widget.employee.salary?.currentRate ?? 0;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${l10n.currentSalary} : ${formatMoney(current)}', style: const TextStyle(fontSize: 17)),
          const SizedBox(height: 12),
          AmountField(controller: _amount, label: l10n.newSalary, autofocus: true),
          const SizedBox(height: 12),
          DateField(
            label: l10n.effectiveFrom,
            value: _from,
            firstDate: widget.employee.hiredOn,
            onChanged: (date) => setState(() => _from = date ?? _from),
          ),
          const SizedBox(height: 20),
          SheetActions(onSave: _save, saving: _saving),
        ],
      ),
    );
  }
}
