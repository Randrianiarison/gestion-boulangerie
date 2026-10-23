import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/format.dart';
import '../../core/labels.dart';
import '../../core/theme.dart';
import '../../data/outbox.dart';
import '../../data/providers.dart';
import '../../models/stock.dart';
import '../../widgets/async_view.dart';
import '../../widgets/cards.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/quantity_stepper.dart';

/// Production du matin : une quantité par produit, puis une seule validation.
class ProductionScreen extends ConsumerStatefulWidget {
  const ProductionScreen({super.key});

  @override
  ConsumerState<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends ConsumerState<ProductionScreen> {
  final Map<int, int> _quantities = {};
  bool _saving = false;

  int get _lineCount => _quantities.values.where((quantity) => quantity > 0).length;

  Future<void> _save(List<Product> products) async {
    final l10n = context.l10n;
    final lines = [
      for (final product in products)
        if ((_quantities[product.id] ?? 0) > 0) (product: product, quantity: _quantities[product.id]!),
    ];
    if (lines.isEmpty) return;

    final confirmed = await confirmDialog(
      context,
      title: l10n.productionConfirmTitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('${formatInt(line.quantity)} × ${line.product.label(context)}', style: const TextStyle(fontSize: 17)),
            ),
        ],
      ),
    );
    if (!confirmed || !mounted) return;

    setState(() => _saving = true);
    try {
      final production = OutboxOperation.create(OutboxKind.production, [
        for (final line in lines)
          (
            productId: line.product.id,
            quantity: line.quantity,
            unitPrice: line.product.unitPrice,
            label: line.product.label(context),
          ),
      ]);
      final result = await ref.read(outboxProvider.notifier).submit(production);
      if (!mounted) return;
      switch (result.outcome) {
        case SubmitOutcome.sent:
          showSuccess(context, l10n.productionSaved);
        case SubmitOutcome.queued:
          showQueued(context, l10n.productionQueued);
        case SubmitOutcome.rejected:
          showError(context, ApiException(ApiErrorKind.business, message: result.error));
      }
      setState(_quantities.clear);
      invalidateStock(ref);
    } on Object catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final products = ref.watch(activeProductsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.productionTitle)),
      body: AsyncView(
        value: products,
        onRetry: () => ref.invalidate(activeProductsProvider),
        builder: (products) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            const _TodayLots(),
            for (final category in ProductCategory.values) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                child: Text(
                  l10n.categoryLabel(category),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              for (final product in products.where((p) => p.category == category))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        Expanded(
                          child: Text(
                            product.label(context),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ),
                        QuantityStepper(
                          value: _quantities[product.id] ?? 0,
                          dialogTitle: product.label(context),
                          onChanged: (quantity) => setState(() => _quantities[product.id] = quantity),
                        ),
                      ]),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _saving || _lineCount == 0 || products is! AsyncData<List<Product>>
                ? null
                : () => _save(products.value),
            icon: const Icon(Icons.save_rounded),
            label: Text(_lineCount == 0 ? l10n.productionNothing : '${l10n.productionSave} ($_lineCount)'),
          ),
        ),
      ),
    );
  }
}

/// Ce qui a déjà été enregistré ce matin ; un lot pas encore vendu peut être supprimé (erreur de saisie).
class _TodayLots extends ConsumerWidget {
  const _TodayLots();

  Future<void> _delete(BuildContext context, WidgetRef ref, StockLot lot) async {
    final l10n = context.l10n;
    final confirmed = await confirmDialog(
      context,
      title: l10n.deleteLotConfirm(formatInt(lot.quantityProduced), lot.product?.label(context) ?? ''),
      confirmLabel: l10n.delete,
      danger: true,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(bakeryApiProvider).deleteLot(lot.id);
      if (!context.mounted) return;
      showSuccess(context, l10n.lotDeleted);
      invalidateStock(ref);
    } on Object catch (error) {
      if (context.mounted) showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lots = ref.watch(productionTodayProvider).value ?? const [];
    if (lots.isEmpty) return const SizedBox.shrink();

    return SectionCard(
      title: context.l10n.productionAlreadyToday,
      icon: Icons.check_circle_rounded,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final lot in lots)
            InputChip(
              avatar: const Icon(Icons.bakery_dining_rounded, color: AppColors.bread),
              label: Text('${lot.product?.label(context) ?? ''} × ${formatInt(lot.quantityProduced)}'),
              onDeleted: lot.untouched ? () => _delete(context, ref, lot) : null,
            ),
        ],
      ),
    );
  }
}
