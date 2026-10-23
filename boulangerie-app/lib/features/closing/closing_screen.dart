import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/labels.dart';
import '../../core/theme.dart';
import '../../data/outbox.dart';
import '../../data/providers.dart';
import '../../router.dart';
import '../../models/stock.dart';
import '../../widgets/async_view.dart';
import '../../widgets/cards.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/quantity_stepper.dart';
import 'waste_sheet.dart';

/// Clôture du soir : on compte ce qui reste, l'appli montre vendu / invendus avant validation.
class ClosingScreen extends ConsumerStatefulWidget {
  const ClosingScreen({super.key});

  @override
  ConsumerState<ClosingScreen> createState() => _ClosingScreenState();
}

class _ClosingScreenState extends ConsumerState<ClosingScreen> {
  DateTime _date = today();
  final Map<int, int> _remaining = {};
  final Map<int, TextEditingController> _recovered = {};
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in _recovered.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _changeDate(int days) {
    setState(() {
      _date = _date.add(Duration(days: days));
      _remaining.clear();
      for (final controller in _recovered.values) {
        controller.clear();
      }
    });
  }

  TextEditingController _recoveredController(int productId) =>
      _recovered.putIfAbsent(productId, TextEditingController.new);

  bool _allCounted(List<StockRow> rows) => rows.where((row) => row.available > 0).every((row) => _remaining.containsKey(row.product.id));

  ({int sales, int unsold}) _preview(List<StockRow> rows) {
    var sales = 0;
    var unsold = 0;
    for (final row in rows) {
      final remaining = _remaining[row.product.id];
      if (remaining == null && row.available > 0) continue;
      sales += row.soldFor(remaining ?? 0) * row.product.unitPrice;
      unsold += row.unsoldFor(remaining ?? 0);
    }
    return (sales: sales, unsold: unsold);
  }

  Future<void> _validate(List<StockRow> rows) async {
    final l10n = context.l10n;
    final preview = _preview(rows);

    final confirmed = await confirmDialog(
      context,
      title: l10n.closingConfirmTitle(context.dates.short(_date)),
      confirmLabel: l10n.closingValidate,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.closingConfirmBody),
          const SizedBox(height: 12),
          AmountRow(label: l10n.closingSalesTotal, amount: preview.sales, bold: true),
          Row(children: [
            Expanded(child: Text(l10n.closingWasteTotal)),
            CountText(preview.unsold, style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
    if (!confirmed || !mounted) return;

    setState(() => _saving = true);
    try {
      await ref.read(bakeryApiProvider).closeDay(_date, [
        for (final row in rows)
          (
            productId: row.product.id,
            remaining: _remaining[row.product.id] ?? 0,
            recoveredAmount: parseInt(_recovered[row.product.id]?.text ?? ''),
          ),
      ]);
      if (!mounted) return;
      showSuccess(context, l10n.closingSaved);
      setState(_remaining.clear);
      invalidateStock(ref);
    } on Object catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cancelClosing() async {
    final l10n = context.l10n;
    final confirmed = await confirmDialog(
      context,
      title: l10n.closingCancel,
      content: Text(l10n.closingCancelConfirm(context.dates.short(_date))),
      confirmLabel: l10n.closingCancel,
      danger: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await ref.read(bakeryApiProvider).cancelClosing(_date);
      if (!mounted) return;
      showSuccess(context, l10n.closingCancelled);
      invalidateStock(ref);
    } on Object catch (error) {
      if (mounted) showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(dayClosingProvider(_date));
    final rows = state.value?.canClose == true ? state.value!.items : const <StockRow>[];
    // Une vente pas encore reçue par le serveur fausserait le calcul « vendu = disponible − restant ».
    final pendingOps = ref
        .watch(outboxProvider)
        .where((operation) => operation.isPending && !operation.date.isAfter(_date))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.closingTitle),
        actions: [
          IconButton(
            tooltip: l10n.wasteDeclare,
            icon: const Icon(Icons.heart_broken_rounded),
            onPressed: () async {
              if (await showWasteSheet(context) && mounted) invalidateStock(ref);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: PeriodNavigator(
              label: _date == today() ? '${l10n.today} · ${context.dates.long(_date)}' : context.dates.long(_date),
              previousTooltip: l10n.previousDay,
              nextTooltip: l10n.nextDay,
              onPrevious: () => _changeDate(-1),
              onNext: _date.isBefore(today()) ? () => _changeDate(1) : null,
            ),
          ),
          Expanded(
            child: AsyncView(
              value: state,
              onRetry: () => ref.invalidate(dayClosingProvider(_date)),
              builder: (state) {
                if (state.closed) {
                  return _ClosedSummary(state: state, onCancel: state.canCancel ? _cancelClosing : null);
                }
                if (!state.canClose) {
                  return _Message(
                    icon: Icons.block_rounded,
                    text: state.blockedReason == 'future_date' ? l10n.closingBlockedFuture : l10n.closingBlockedPeriod,
                  );
                }
                // Dans la liste (et non figé en haut) : sur un petit écran, il ne cache pas les produits.
                final pendingWarning = pendingOps == 0
                    ? null
                    : Card(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        child: ListTile(
                          leading: const Icon(Icons.cloud_upload_rounded, color: AppColors.warning, size: 32),
                          title: Text(l10n.closingPendingOps(formatInt(pendingOps))),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push(Routes.outbox),
                        ),
                      );
                if (state.items.isEmpty) {
                  return ListView(padding: const EdgeInsets.all(16), children: [
                    ?pendingWarning,
                    _Message(icon: Icons.inventory_2_outlined, text: l10n.closingNothingToCount),
                  ]);
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 160),
                  children: [
                    if (pendingWarning != null) ...[pendingWarning, const SizedBox(height: 12)],
                    Text(l10n.closingInstructions, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    for (final row in state.items)
                      _CountCard(
                        row: row,
                        remaining: _remaining[row.product.id],
                        recovered: _recoveredController(row.product.id),
                        onChanged: (value) => setState(() => _remaining[row.product.id] = value),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: state.value?.canClose == true
          ? _ValidateBar(
              preview: _preview(rows),
              ready: _allCounted(rows) && pendingOps == 0,
              saving: _saving,
              onValidate: () => _validate(rows),
            )
          : null,
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.row, required this.remaining, required this.recovered, required this.onChanged});

  final StockRow row;
  final int? remaining;
  final TextEditingController recovered;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final counted = remaining != null || row.available == 0;
    final sold = row.soldFor(remaining ?? 0);
    final unsold = row.unsoldFor(remaining ?? 0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(row.product.label(context), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Wrap(spacing: 8, runSpacing: 4, children: [
                StatusChip(label: l10n.available(formatInt(row.available)), color: AppColors.info),
                if (row.expiring > 0)
                  StatusChip(
                    icon: Icons.schedule_rounded,
                    label: l10n.expiringTonight(formatInt(row.expiring)),
                    color: AppColors.warning,
                  ),
              ]),
              if (row.available > 0) ...[
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: Text(l10n.closingRemaining, style: theme.textTheme.titleMedium)),
                  QuantityStepper(
                    value: remaining,
                    max: row.available,
                    dialogTitle: '${l10n.closingRemaining} · ${row.product.label(context)}',
                    onChanged: onChanged,
                  ),
                ]),
              ],
              const SizedBox(height: 8),
              if (!counted)
                Text(l10n.closingNotCounted, style: TextStyle(color: theme.colorScheme.outline, fontStyle: FontStyle.italic))
              else ...[
                Text(
                  '${l10n.closingSold} : ${formatInt(sold)} · ${formatMoney(sold * row.product.unitPrice)}',
                  style: const TextStyle(fontSize: 16, color: AppColors.success, fontWeight: FontWeight.w600),
                ),
                if (unsold > 0) ...[
                  Text(
                    '${l10n.closingUnsold} : ${formatInt(unsold)}',
                    style: const TextStyle(fontSize: 16, color: AppColors.danger, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: recovered,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: l10n.closingRecovered, suffixText: 'Ar', isDense: true),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ValidateBar extends StatelessWidget {
  const _ValidateBar({required this.preview, required this.ready, required this.saving, required this.onValidate});

  final ({int sales, int unsold}) preview;
  final bool ready;
  final bool saving;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(spacing: 16, runSpacing: 4, alignment: WrapAlignment.spaceBetween, children: [
              Text('${l10n.closingSold} : ${formatMoney(preview.sales)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              Text('${l10n.closingUnsold} : ${formatInt(preview.unsold)}', style: const TextStyle(fontSize: 17, color: AppColors.danger)),
            ]),
            if (!ready)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(l10n.closingCountAll, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: ready && !saving ? onValidate : null,
              icon: const Icon(Icons.lock_rounded),
              label: Text(l10n.closingValidate),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClosedSummary extends StatelessWidget {
  const _ClosedSummary({required this.state, required this.onCancel});

  final DayClosingState state;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final closing = state.closing!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: AppColors.success.withValues(alpha: 0.12),
          child: ListTile(
            leading: const Icon(Icons.lock_rounded, color: AppColors.success, size: 36),
            title: Text(l10n.closingAlreadyClosed, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Text(
              closing.automatic ? l10n.closingAutomatic : l10n.closingClosedBy(closing.closedBy ?? '—'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: l10n.closingSalesTotal,
          icon: Icons.point_of_sale_rounded,
          child: Column(children: [
            for (final sale in closing.sales)
              AmountRow(label: '${formatInt(sale.quantity)} × ${sale.product?.label(context) ?? ''}', amount: sale.total),
            const Divider(),
            AmountRow(label: l10n.total, amount: closing.salesTotal, bold: true),
          ]),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: l10n.closingWasteTotal,
          icon: Icons.delete_sweep_rounded,
          child: Column(children: [
            for (final record in closing.wasteRecords)
              AmountRow(
                label: '${formatInt(record.quantity)} × ${record.product?.label(context) ?? ''}',
                amount: record.lostValue,
                color: AppColors.danger,
              ),
            if (closing.wasteRecords.isEmpty) Text(l10n.noData),
            const Divider(),
            AmountRow(label: l10n.closingLostValue, amount: closing.wasteValue, color: AppColors.danger),
            if (closing.recoveredTotal > 0) AmountRow(label: l10n.recovered, amount: closing.recoveredTotal, color: AppColors.success),
          ]),
        ),
        if (onCancel != null) ...[
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: onCancel,
            icon: const Icon(Icons.lock_open_rounded),
            label: Text(l10n.closingCancel),
          ),
        ],
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
        ]),
      ),
    );
  }
}
