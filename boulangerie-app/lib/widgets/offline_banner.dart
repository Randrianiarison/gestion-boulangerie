import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/labels.dart';
import '../core/theme.dart';
import '../data/connection.dart';
import '../data/outbox.dart';
import '../router.dart';

/// Bandeau en haut de tous les écrans : hors ligne, opérations en attente ou refusées.
/// Le toucher ouvre la liste d'attente.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(connectionProvider);
    final operations = ref.watch(outboxProvider);
    final pending = operations.where((operation) => operation.isPending).length;
    final rejected = operations.length - pending;

    if (online && operations.isEmpty) return child;

    final l10n = context.l10n;
    final (color, icon, text) = switch ((online, rejected > 0)) {
      (_, true) => (AppColors.danger, Icons.error_rounded, l10n.rejectedOps(formatInt(rejected))),
      (false, _) => (
          AppColors.warning,
          Icons.cloud_off_rounded,
          pending == 0 ? l10n.offline : '${l10n.offline} · ${l10n.pendingOps(formatInt(pending))}',
        ),
      _ => (AppColors.info, Icons.cloud_upload_rounded, l10n.pendingOps(formatInt(pending))),
    };

    return Column(children: [
      Material(
        color: color,
        child: SafeArea(
          bottom: false,
          child: InkWell(
            onTap: () => ref.read(routerProvider).push(Routes.outbox),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ]),
            ),
          ),
        ),
      ),
      // Le bandeau occupe déjà la barre d'état : l'écran en dessous n'a plus à la contourner.
      Expanded(child: MediaQuery.removePadding(context: context, removeTop: true, child: child)),
    ]);
  }
}
