import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/labels.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../models/stock.dart';
import '../../widgets/async_view.dart';
import '../../widgets/dialogs.dart';

/// Vente au comptoir : on touche les grosses tuiles, on vérifie le total, on valide.
class SaleScreen extends ConsumerStatefulWidget {
  const SaleScreen({super.key});

  @override
  ConsumerState<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends ConsumerState<SaleScreen> {
  final Map<int, int> _cart = {};
  bool _saving = false;

  int _total(List<StockRow> rows) =>
      rows.fold(0, (sum, row) => sum + (_cart[row.product.id] ?? 0) * row.product.unitPrice);

  void _add(StockRow row) {
    final inCart = _cart[row.product.id] ?? 0;
    if (inCart < row.available) setState(() => _cart[row.product.id] = inCart + 1);
  }

  void _remove(StockRow row) {
    final inCart = _cart[row.product.id] ?? 0;
    setState(() => inCart <= 1 ? _cart.remove(row.product.id) : _cart[row.product.id] = inCart - 1);
  }

  Future<void> _validate(List<StockRow> rows) async {
    final l10n = context.l10n;
    final lines = rows.where((row) => (_cart[row.product.id] ?? 0) > 0).toList();
    final total = _total(rows);

    final confirmed = await confirmDialog(
      context,
      title: l10n.saleConfirmTitle,
      confirmLabel: l10n.saleValidate,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final row in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(child: Text('${_cart[row.product.id]} × ${row.product.label(context)}')),
                Text(formatMoney(_cart[row.product.id]! * row.product.unitPrice)),
              ]),
            ),
          const Divider(),
          Row(children: [
            Expanded(child: Text(l10n.total, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            Text(formatMoney(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ]),
        ],
      ),
    );
    if (!confirmed || !mounted) return;

    setState(() => _saving = true);
    try {
      final paid = await ref
          .read(bakeryApiProvider)
          .sell([for (final row in lines) (productId: row.product.id, quantity: _cart[row.product.id]!)]);
      if (!mounted) return;
      showSuccess(context, l10n.saleSaved(formatMoney(paid)));
      setState(_cart.clear);
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
    final stock = ref.watch(stockProvider);
    final rows = (stock.value ?? const <StockRow>[]).where((row) => row.product.active).toList();
    final total = _total(rows);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.saleTitle),
        actions: [
          if (_cart.isNotEmpty)
            TextButton.icon(
              onPressed: () => setState(_cart.clear),
              icon: const Icon(Icons.remove_shopping_cart_rounded),
              label: Text(l10n.saleClear),
            ),
        ],
      ),
      body: AsyncView(
        value: stock,
        onRetry: () => ref.invalidate(stockProvider),
        builder: (_) => LayoutBuilder(builder: (context, constraints) {
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: constraints.maxWidth > 600 ? 4 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              return _ProductTile(
                row: row,
                inCart: _cart[row.product.id] ?? 0,
                onAdd: () => _add(row),
                onRemove: () => _remove(row),
              );
            },
          );
        }),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12)],
          ),
          child: _cart.isEmpty
              ? Text(l10n.saleTapToAdd, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      Text(l10n.total, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FittedBox(
                          alignment: Alignment.centerRight,
                          fit: BoxFit.scaleDown,
                          child: Text(
                            formatMoney(total),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                      onPressed: _saving ? null : () => _validate(rows),
                      icon: const Icon(Icons.check_rounded),
                      label: Text(l10n.saleValidate),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.row, required this.inCart, required this.onAdd, required this.onRemove});

  final StockRow row;
  final int inCart;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final product = row.product;
    final left = row.available - inCart;
    final color = product.category == ProductCategory.juice ? AppColors.juice : AppColors.bread;
    final soldOut = row.available == 0;

    return Material(
      color: inCart > 0 ? color.withValues(alpha: 0.18) : theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: left > 0 ? onAdd : null,
        child: Opacity(
          opacity: soldOut ? 0.45 : 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(
                    product.category == ProductCategory.juice ? Icons.local_drink_rounded : Icons.bakery_dining_rounded,
                    color: color,
                    size: 32,
                  ),
                  const Spacer(),
                  if (inCart > 0)
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: color,
                      child: Text('$inCart', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                ]),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    product.label(context),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(formatMoney(product.unitPrice), style: theme.textTheme.titleMedium?.copyWith(color: color)),
                Row(children: [
                  Expanded(
                    child: Text(
                      soldOut ? l10n.outOfStock : l10n.available(formatInt(left)),
                      style: TextStyle(color: soldOut ? AppColors.danger : theme.colorScheme.outline),
                    ),
                  ),
                  if (inCart > 0)
                    IconButton.filledTonal(
                      onPressed: onRemove,
                      icon: const Icon(Icons.remove_rounded),
                      tooltip: '−1',
                    ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
