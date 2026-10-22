import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/labels.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../models/user.dart';
import '../../widgets/async_view.dart';
import '../../widgets/cards.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/fields.dart';

/// Comptes de connexion (owner) : créer un compte employé, changer un PIN oublié, désactiver.
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final users = ref.watch(usersProvider);

    Future<void> edit([AppUser? user]) async {
      final saved = await showFormSheet<bool>(context, title: user?.name ?? l10n.userNew, child: _UserForm(user: user));
      if (saved ?? false) ref.invalidate(usersProvider);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.usersTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: edit,
        icon: const Icon(Icons.person_add_rounded),
        label: Text(l10n.userNew),
      ),
      body: AsyncView(
        value: users,
        onRetry: () => ref.invalidate(usersProvider),
        builder: (users) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            for (final user in users)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    onTap: () => edit(user),
                    leading: Icon(
                      user.isOwner ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                      size: 32,
                      color: user.active ? AppColors.info : Theme.of(context).colorScheme.outline,
                    ),
                    title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${user.phone} · ${l10n.userRoleLabel(user.role)}'),
                    trailing: user.active ? null : StatusChip(label: l10n.inactive, color: AppColors.danger),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UserForm extends ConsumerStatefulWidget {
  const _UserForm({this.user});

  final AppUser? user;

  @override
  ConsumerState<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends ConsumerState<_UserForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user?.name);
  late final _phone = TextEditingController(text: widget.user?.phone);
  final _pin = TextEditingController();
  late UserRole _role = widget.user?.role ?? UserRole.staff;
  late bool _active = widget.user?.active ?? true;
  bool _saving = false;

  bool get _creating => widget.user == null;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(bakeryApiProvider).saveUser(widget.user?.id, {
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'role': _role.name,
        'active': _active,
        if (_pin.text.isNotEmpty) 'pin': _pin.text,
      });
      if (!mounted) return;
      showSuccess(context, context.l10n.userSaved);
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
            decoration: InputDecoration(labelText: l10n.phoneLabel, prefixIcon: const Icon(Icons.phone_android_rounded)),
            validator: (text) => (text ?? '').replaceAll(RegExp(r'\D'), '').length >= 10 ? null : l10n.invalidPhone,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _pin,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: _creating ? l10n.pinLabel : l10n.newPin, helperText: l10n.pinHelp),
            validator: (text) {
              if ((text ?? '').isEmpty && !_creating) return null;
              return RegExp(r'^\d{4,6}$').hasMatch(text ?? '') ? null : l10n.invalidPin;
            },
          ),
          const SizedBox(height: 12),
          SegmentedButton<UserRole>(
            segments: [
              for (final role in UserRole.values) ButtonSegment(value: role, label: Text(l10n.userRoleLabel(role))),
            ],
            selected: {_role},
            onSelectionChanged: (selection) => setState(() => _role = selection.first),
          ),
          if (!_creating)
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
