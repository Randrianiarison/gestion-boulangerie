import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/labels.dart';
import '../../data/providers.dart';
import '../../models/stock.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/fields.dart';

/// Produit abîmé (tombé, écrasé…) retiré du stock. Renvoie true si enregistré.
Future<bool> showWasteSheet(BuildContext context) async {
  final saved = await showFormSheet<bool>(context, title: context.l10n.wasteDeclare, child: const _WasteForm());
  return saved ?? false;
}

class _WasteForm extends ConsumerStatefulWidget {
  const _WasteForm();

  @override
  ConsumerState<_WasteForm> createState() => _WasteFormState();
}

class _WasteFormState extends ConsumerState<_WasteForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _note = TextEditingController();
  int? _productId;
  WasteReason _reason = WasteReason.damaged;
  bool _saving = false;

  @override
  void dispose() {
    _quantity.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(bakeryApiProvider).declareWaste(
            productId: _productId!,
            quantity: int.parse(_quantity.text),
            reason: _reason,
            note: _note.text.trim(),
          );
      if (!mounted) return;
      showSuccess(context, context.l10n.wasteSaved);
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
    final rows = (ref.watch(stockProvider).value ?? const <StockRow>[]).where((row) => row.available > 0).toList();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<int>(
            initialValue: _productId,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.menuProducts),
            items: [
              for (final row in rows)
                DropdownMenuItem(value: row.product.id, child: Text('${row.product.label(context)} (${row.available})')),
            ],
            onChanged: (id) => setState(() => _productId = id),
            validator: (id) => id == null ? l10n.fieldRequired : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _quantity,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: l10n.quantity),
            validator: (text) => (int.tryParse(text ?? '') ?? 0) > 0 ? null : l10n.invalidNumber,
          ),
          const SizedBox(height: 12),
          SegmentedButton<WasteReason>(
            segments: [
              ButtonSegment(value: WasteReason.damaged, label: Text(l10n.wasteDamaged)),
              ButtonSegment(value: WasteReason.other, label: Text(l10n.wasteOther)),
            ],
            selected: {_reason},
            onSelectionChanged: (selection) => setState(() => _reason = selection.first),
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _note, decoration: InputDecoration(labelText: l10n.note)),
          const SizedBox(height: 20),
          SheetActions(onSave: _save, saving: _saving),
        ],
      ),
    );
  }
}
