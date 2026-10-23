import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/labels.dart';
import '../../core/theme.dart';
import '../../data/connection.dart';
import '../../data/outbox.dart';
import '../../widgets/cards.dart';
import '../../widgets/dialogs.dart';

/// Ventes et productions faites sans connexion, pas encore reçues par le serveur.
class OutboxScreen extends ConsumerStatefulWidget {
  const OutboxScreen({super.key});

  @override
  ConsumerState<OutboxScreen> createState() => _OutboxScreenState();
}

class _OutboxScreenState extends ConsumerState<OutboxScreen> {
  bool _sending = false;

  Future<void> _sendNow() async {
    final l10n = context.l10n;
    setState(() => _sending = true);
    // Un essai réel, même si l'appli se croit hors ligne.
    await ref.read(connectionProvider.notifier).check();
    await ref.read(outboxProvider.notifier).flush();
    if (!mounted) return;
    setState(() => _sending = false);

    final pending = ref.read(outboxProvider).where((operation) => operation.isPending).length;
    if (pending == 0) {
      showSuccess(context, l10n.outboxEmpty);
    } else {
      showQueued(context, l10n.outboxStillOffline);
    }
  }

  Future<void> _discard(OutboxOperation operation) async {
    final l10n = context.l10n;
    final confirmed = await confirmDialog(context, title: l10n.outboxDiscardConfirm, confirmLabel: l10n.delete, danger: true);
    if (confirmed) ref.read(outboxProvider.notifier).discard(operation.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final operations = ref.watch(outboxProvider);
    final pending = operations.where((operation) => operation.isPending).length;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.outboxTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.outboxHint, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          if (operations.isEmpty)
            Card(
              color: AppColors.success.withValues(alpha: 0.12),
              child: ListTile(
                leading: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 36),
                title: Text(l10n.outboxEmpty, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          if (pending > 0) ...[
            FilledButton.icon(
              onPressed: _sending ? null : _sendNow,
              icon: _sending
                  ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3))
                  : const Icon(Icons.cloud_upload_rounded),
              label: Text(l10n.outboxSendNow),
            ),
            const SizedBox(height: 16),
          ],
          for (final operation in operations)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _OperationCard(
                operation: operation,
                onRetry: () => ref.read(outboxProvider.notifier).retry(operation.id),
                onDiscard: () => _discard(operation),
              ),
            ),
        ],
      ),
    );
  }
}

class _OperationCard extends StatelessWidget {
  const _OperationCard({required this.operation, required this.onRetry, required this.onDiscard});

  final OutboxOperation operation;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isSale = operation.kind == OutboxKind.sale;
    final color = operation.isPending ? AppColors.warning : AppColors.danger;
    final time = '${operation.createdAt.hour.toString().padLeft(2, '0')}:${operation.createdAt.minute.toString().padLeft(2, '0')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(isSale ? Icons.point_of_sale_rounded : Icons.bakery_dining_rounded, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${isSale ? l10n.menuSale : l10n.menuProduction} · ${context.dates.short(operation.date)} $time',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
              StatusChip(label: operation.isPending ? l10n.outboxPending : l10n.outboxRejected, color: color),
            ]),
            const SizedBox(height: 8),
            for (final line in operation.lines)
              Text('${formatInt(line.quantity)} × ${line.label}', style: const TextStyle(fontSize: 16)),
            if (isSale) ...[
              const SizedBox(height: 4),
              Text(formatMoney(operation.total), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
            if (!operation.isPending) ...[
              const SizedBox(height: 8),
              Text(operation.error ?? l10n.errorUnknown, style: const TextStyle(color: AppColors.danger)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: onDiscard, child: Text(l10n.delete))),
                const SizedBox(width: 12),
                Expanded(child: FilledButton(onPressed: onRetry, child: Text(l10n.retry))),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}
