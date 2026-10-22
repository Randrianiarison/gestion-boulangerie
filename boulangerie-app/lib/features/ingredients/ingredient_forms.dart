import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/labels.dart';
import '../../data/providers.dart';
import '../../models/ingredient.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/fields.dart';

/// Achat d'un ingrédient : quantité, puis le total payé OU le prix unitaire.
Future<bool> showPurchaseSheet(BuildContext context, Ingredient ingredient) async {
  final saved = await showFormSheet<bool>(
    context,
    title: context.l10n.ingredientPurchaseTitle(ingredient.name(context.lang)),
    child: _PurchaseForm(ingredient: ingredient),
  );
  return saved ?? false;
}

/// Utilisation (saisie facultative) : retire du stock.
Future<bool> showUsageSheet(BuildContext context, Ingredient ingredient) async {
  final saved = await showFormSheet<bool>(
    context,
    title: context.l10n.ingredientUsageTitle(ingredient.name(context.lang)),
    child: _UsageForm(ingredient: ingredient),
  );
  return saved ?? false;
}

/// Création ou modification d'un ingrédient (owner).
Future<bool> showIngredientSheet(BuildContext context, {Ingredient? ingredient}) async {
  final l10n = context.l10n;
  final saved = await showFormSheet<bool>(
    context,
    title: ingredient == null ? l10n.ingredientNew : ingredient.name(context.lang),
    child: _IngredientForm(ingredient: ingredient),
  );
  return saved ?? false;
}

enum _PriceMode { total, unit }

class _PurchaseForm extends ConsumerStatefulWidget {
  const _PurchaseForm({required this.ingredient});

  final Ingredient ingredient;

  @override
  ConsumerState<_PurchaseForm> createState() => _PurchaseFormState();
}

class _PurchaseFormState extends ConsumerState<_PurchaseForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _amount = TextEditingController();
  final _supplier = TextEditingController();
  _PriceMode _mode = _PriceMode.total;
  DateTime _date = today();
  bool _saving = false;

  @override
  void dispose() {
    _quantity.dispose();
    _amount.dispose();
    _supplier.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = parseInt(_amount.text)!;

    setState(() => _saving = true);
    try {
      await ref.read(bakeryApiProvider).purchaseIngredient(
            ingredientId: widget.ingredient.id,
            quantity: parseDecimal(_quantity.text)!,
            total: _mode == _PriceMode.total ? amount : null,
            unitPrice: _mode == _PriceMode.unit ? amount : null,
            date: _date,
            supplier: _supplier.text.trim(),
          );
      if (!mounted) return;
      showSuccess(context, context.l10n.purchaseSaved);
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
    final unit = l10n.unitLabel(widget.ingredient.unit);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecimalField(controller: _quantity, label: l10n.quantityIn(unit), suffix: unit, autofocus: true),
          const SizedBox(height: 16),
          Text(l10n.priceMode),
          const SizedBox(height: 6),
          SegmentedButton<_PriceMode>(
            segments: [
              ButtonSegment(value: _PriceMode.total, label: Text(l10n.totalPaid)),
              ButtonSegment(value: _PriceMode.unit, label: Text('${l10n.unitPrice} / $unit')),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) => setState(() => _mode = selection.first),
          ),
          const SizedBox(height: 12),
          AmountField(controller: _amount, label: _mode == _PriceMode.total ? l10n.totalPaid : l10n.unitPrice),
          const SizedBox(height: 12),
          TextFormField(controller: _supplier, decoration: InputDecoration(labelText: l10n.supplier)),
          const SizedBox(height: 12),
          DateField(label: l10n.date, value: _date, lastDate: today(), onChanged: (date) => setState(() => _date = date ?? today())),
          const SizedBox(height: 20),
          SheetActions(onSave: _save, saving: _saving),
        ],
      ),
    );
  }
}

class _UsageForm extends ConsumerStatefulWidget {
  const _UsageForm({required this.ingredient});

  final Ingredient ingredient;

  @override
  ConsumerState<_UsageForm> createState() => _UsageFormState();
}

class _UsageFormState extends ConsumerState<_UsageForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  DateTime _date = today();
  bool _saving = false;

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(bakeryApiProvider).useIngredient(
            ingredientId: widget.ingredient.id,
            quantity: parseDecimal(_quantity.text)!,
            date: _date,
          );
      if (!mounted) return;
      showSuccess(context, context.l10n.usageSaved);
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
    final unit = l10n.unitLabel(widget.ingredient.unit);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${l10n.ingredientStock} : ${formatQuantity(widget.ingredient.stock)} $unit'),
          const SizedBox(height: 12),
          DecimalField(controller: _quantity, label: l10n.quantityIn(unit), suffix: unit, autofocus: true),
          const SizedBox(height: 12),
          DateField(label: l10n.date, value: _date, lastDate: today(), onChanged: (date) => setState(() => _date = date ?? today())),
          const SizedBox(height: 20),
          SheetActions(onSave: _save, saving: _saving),
        ],
      ),
    );
  }
}

class _IngredientForm extends ConsumerStatefulWidget {
  const _IngredientForm({this.ingredient});

  final Ingredient? ingredient;

  @override
  ConsumerState<_IngredientForm> createState() => _IngredientFormState();
}

class _IngredientFormState extends ConsumerState<_IngredientForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nameFr = TextEditingController(text: widget.ingredient?.nameFr);
  late final _nameMg = TextEditingController(text: widget.ingredient?.nameMg);
  late final _threshold = TextEditingController(
    text: widget.ingredient == null ? '' : formatQuantity(widget.ingredient!.alertThreshold).replaceAll(' ', ''),
  );
  late IngredientUnit _unit = widget.ingredient?.unit ?? IngredientUnit.kg;
  late bool _active = widget.ingredient?.active ?? true;
  bool _saving = false;

  @override
  void dispose() {
    _nameFr.dispose();
    _nameMg.dispose();
    _threshold.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(bakeryApiProvider).saveIngredient(widget.ingredient?.id, {
        'name_fr': _nameFr.text.trim(),
        'name_mg': _nameMg.text.trim(),
        'unit': _unit.name,
        'alert_threshold': parseDecimal(_threshold.text),
        'active': _active,
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
    String? required(String? text) => (text ?? '').trim().isEmpty ? l10n.fieldRequired : null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(controller: _nameMg, decoration: InputDecoration(labelText: l10n.nameMg), validator: required),
          const SizedBox(height: 12),
          TextFormField(controller: _nameFr, decoration: InputDecoration(labelText: l10n.nameFr), validator: required),
          const SizedBox(height: 12),
          DropdownButtonFormField<IngredientUnit>(
            initialValue: _unit,
            decoration: InputDecoration(labelText: l10n.unit),
            items: [for (final unit in IngredientUnit.values) DropdownMenuItem(value: unit, child: Text(l10n.unitLabel(unit)))],
            onChanged: (unit) => setState(() => _unit = unit ?? _unit),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _threshold,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.ingredientThreshold, suffixText: l10n.unitLabel(_unit)),
            validator: (text) => parseDecimal(text ?? '') == null ? l10n.invalidNumber : null,
          ),
          if (widget.ingredient != null)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.active),
              value: _active,
              onChanged: (value) => setState(() => _active = value),
            ),
          const SizedBox(height: 20),
          SheetActions(onSave: _save, saving: _saving),
        ],
      ),
    );
  }
}
