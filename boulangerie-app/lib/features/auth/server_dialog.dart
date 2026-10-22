import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/labels.dart';
import '../../core/settings.dart';

/// Adresse de l'API (ex. http://192.168.1.20:8000/api sur le Wi-Fi de la boutique).
Future<void> showServerDialog(BuildContext context) {
  return showDialog<void>(context: context, builder: (context) => const _ServerDialog());
}

class _ServerDialog extends ConsumerStatefulWidget {
  const _ServerDialog();

  @override
  ConsumerState<_ServerDialog> createState() => _ServerDialogState();
}

class _ServerDialogState extends ConsumerState<_ServerDialog> {
  late final _controller = TextEditingController(text: ref.read(apiUrlProvider));
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(apiUrlProvider.notifier).change(_controller.text);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.serverSettings),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(labelText: l10n.serverUrlLabel, helperText: l10n.serverUrlHelp, helperMaxLines: 2),
          validator: (text) {
            final uri = Uri.tryParse(text?.trim() ?? '');
            final valid = uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
            return valid ? null : l10n.invalidUrl;
          },
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(onPressed: () => _controller.text = defaultApiUrl, child: const Icon(Icons.restart_alt_rounded)),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}
