import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/labels.dart';
import '../../core/settings.dart';
import '../../core/theme.dart';
import '../../data/outbox.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/language_switch.dart';
import '../auth/auth_controller.dart';
import '../auth/server_dialog.dart';

/// Langue, adresse du serveur, déconnexion.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_circle_rounded, size: 40),
                title: Text(l10n.connectedAs(user.name), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${user.phone} · ${l10n.userRoleLabel(user.role)}'),
              ),
            ),
          const SizedBox(height: 16),
          Text(l10n.language, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const LanguageSwitch(),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: Text(l10n.serverSettings),
              subtitle: Text(ref.watch(apiUrlProvider)),
              trailing: const Icon(Icons.edit_rounded),
              onTap: () => showServerDialog(context),
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () async {
              final pending = ref.read(outboxProvider).where((operation) => operation.isPending).length;
              final confirmed = await confirmDialog(
                context,
                title: l10n.logoutConfirm,
                content: pending == 0 ? null : Text(l10n.logoutPendingOps(formatInt(pending))),
                confirmLabel: l10n.logout,
                danger: true,
              );
              if (confirmed) await ref.read(authProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout_rounded),
            label: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}
