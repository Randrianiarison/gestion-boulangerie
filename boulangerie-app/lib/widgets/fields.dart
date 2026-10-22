import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/format.dart';
import '../core/labels.dart';

/// Montant en Ariary (entier), suffixe « Ar ».
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    required this.label,
    this.required = true,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final bool required;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      decoration: InputDecoration(labelText: label, suffixText: 'Ar', prefixIcon: const Icon(Icons.payments_outlined)),
      validator: (text) {
        if (text == null || text.isEmpty) return required ? l10n.fieldRequired : null;
        return parseInt(text) == null ? l10n.invalidNumber : null;
      },
    );
  }
}

/// Quantité décimale (2,5 kg).
class DecimalField extends StatelessWidget {
  const DecimalField({
    super.key,
    required this.controller,
    required this.label,
    this.suffix,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String? suffix;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      validator: (text) {
        final value = parseDecimal(text ?? '');
        if (text == null || text.isEmpty) return l10n.fieldRequired;
        return value == null || value <= 0 ? l10n.invalidNumber : null;
      },
    );
  }
}

/// Date affichée en toutes lettres ; toucher ouvre le calendrier.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.clearable = false,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool clearable;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final now = today();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: firstDate ?? DateTime(now.year - 5),
          lastDate: lastDate ?? DateTime(now.year + 2),
        );
        if (picked != null) onChanged(dateOnly(picked));
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_rounded),
          suffixIcon: clearable && value != null
              ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () => onChanged(null))
              : null,
        ),
        child: Text(value == null ? '—' : context.dates.long(value!), style: const TextStyle(fontSize: 17)),
      ),
    );
  }
}

/// Bas de formulaire en feuille modale : Annuler / Enregistrer.
class SheetActions extends StatelessWidget {
  const SheetActions({super.key, required this.onSave, required this.saving, this.saveLabel});

  final VoidCallback onSave;
  final bool saving;
  final String? saveLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel))),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: saving ? null : onSave,
            child: saving
                ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3))
                : Text(saveLabel ?? l10n.save),
          ),
        ),
      ],
    );
  }
}

/// Feuille modale scrollable qui remonte au-dessus du clavier.
Future<T?> showFormSheet<T>(BuildContext context, {required String title, required Widget child}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    ),
  );
}
