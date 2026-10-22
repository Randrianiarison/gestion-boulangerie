import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/labels.dart';
import '../../core/theme.dart';
import '../../widgets/language_switch.dart';
import 'auth_controller.dart';
import 'server_dialog.dart';

/// Connexion par numéro de téléphone et code PIN, avec choix de la langue.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _pin = TextEditingController();
  bool _busy = false;
  Object? _error;

  @override
  void dispose() {
    _phone.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // En cas de succès, le routeur affiche l'accueil tout seul.
      await ref.read(authProvider.notifier).login(_phone.text, _pin.text);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: l10n.serverSettings,
            icon: const Icon(Icons.dns_outlined),
            onPressed: () => showServerDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.bakery_dining_rounded, size: 88, color: theme.colorScheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      l10n.appTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    const LanguageSwitch(),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
                      style: const TextStyle(fontSize: 20),
                      decoration: InputDecoration(labelText: l10n.phoneLabel, prefixIcon: const Icon(Icons.phone_android_rounded)),
                      validator: (text) {
                        final digits = (text ?? '').replaceAll(RegExp(r'\D'), '');
                        return digits.length == 10 || (digits.startsWith('261') && digits.length == 12)
                            ? null
                            : l10n.invalidPhone;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pin,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 24, letterSpacing: 8),
                      decoration: InputDecoration(labelText: l10n.pinLabel, prefixIcon: const Icon(Icons.lock_rounded)),
                      validator: (text) => RegExp(r'^\d{4,6}$').hasMatch(text ?? '') ? null : l10n.invalidPin,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_rounded, color: AppColors.danger),
                          const SizedBox(width: 12),
                          Expanded(child: Text(errorText(l10n, _error!), style: const TextStyle(color: AppColors.danger))),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _busy ? null : _submit,
                      icon: _busy
                          ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3))
                          : const Icon(Icons.login_rounded),
                      label: Text(l10n.loginButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
