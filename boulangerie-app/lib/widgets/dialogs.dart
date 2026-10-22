import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_exception.dart';
import '../core/labels.dart';
import '../core/theme.dart';

/// Confirmation avant toute validation : titre, détail, Oui / Non bien visibles.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  Widget? content,
  String? confirmLabel,
  bool danger = false,
}) async {
  final l10n = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: content == null ? null : SingleChildScrollView(child: content),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.no)),
        FilledButton(
          style: danger ? FilledButton.styleFrom(backgroundColor: AppColors.danger) : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel ?? l10n.yes),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      backgroundColor: AppColors.success,
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 16))),
      ]),
    ));
}

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      backgroundColor: AppColors.danger,
      duration: const Duration(seconds: 6),
      content: Row(children: [
        const Icon(Icons.error_rounded, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(child: Text(errorText(context.l10n, error), style: const TextStyle(fontSize: 16))),
      ]),
    ));
}

/// Saisie d'un nombre entier au clavier numérique (ex. 120 baguettes).
Future<int?> askNumber(BuildContext context, {required String title, int? initial, int? max}) {
  return showDialog<int>(
    context: context,
    builder: (context) => _NumberDialog(title: title, initial: initial, max: max),
  );
}

class _NumberDialog extends StatefulWidget {
  const _NumberDialog({required this.title, this.initial, this.max});

  final String title;
  final int? initial;
  final int? max;

  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  late final _controller = TextEditingController(text: widget.initial?.toString() ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text);
    if (value != null && value >= 0 && (widget.max == null || value <= widget.max!)) {
      Navigator.pop(context, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        decoration: InputDecoration(helperText: widget.max == null ? null : '≤ ${widget.max}'),
        onSubmitted: (_) => _submit(),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: _submit, child: Text(l10n.confirm)),
      ],
    );
  }
}
