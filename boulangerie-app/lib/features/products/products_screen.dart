import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/labels.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../models/stock.dart';
import '../../widgets/async_view.dart';
import '../../widgets/cards.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/fields.dart';

/// Catalogue (owner) : prix, durée de conservation, produits actifs.
class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final products = ref.watch(allProductsProvider);

    Future<void> edit([Product? product]) async {
      final saved = await showFormSheet<bool>(
        context,
        title: product?.label(context) ?? l10n.productNew,
        child: _ProductForm(product: product),
      );
      if (saved ?? false) ref.invalidate(allProductsProvider);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.productsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: edit,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.productNew),
      ),
      body: AsyncView(
        value: products,
        onRetry: () => ref.invalidate(allProductsProvider),
        builder: (products) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            for (final product in products)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    onTap: () => edit(product),
                    leading: Icon(
                      product.category == ProductCategory.juice ? Icons.local_drink_rounded : Icons.bakery_dining_rounded,
                      color: product.category == ProductCategory.juice ? AppColors.juice : AppColors.bread,
                      size: 32,
                    ),
                    title: Text(product.label(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${l10n.shelfLife} : ${product.shelfLifeDays}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatMoney(product.unitPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (!product.active) StatusChip(label: l10n.inactive, color: AppColors.danger),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductForm extends ConsumerStatefulWidget {
  const _ProductForm({this.product});

  final Product? product;

  @override
  ConsumerState<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<_ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nameFr = TextEditingController(text: widget.product?.nameFr);
  late final _nameMg = TextEditingController(text: widget.product?.nameMg);
  late final _price = TextEditingController(text: widget.product?.unitPrice.toString());
  late final _shelfLife = TextEditingController(text: (widget.product?.shelfLifeDays ?? 1).toString());
  late ProductCategory _category = widget.product?.category ?? ProductCategory.bread;
  late ProductFormat _format = widget.product?.format ?? ProductFormat.piece;
  late bool _active = widget.product?.active ?? true;
  bool _saving = false;

  @override
  void dispose() {
    _nameFr.dispose();
    _nameMg.dispose();
    _price.dispose();
    _shelfLife.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(bakeryApiProvider).saveProduct(widget.product?.id, {
        'category': _category.name,
        'name_fr': _nameFr.text.trim(),
        'name_mg': _nameMg.text.trim(),
        'format': _format.name,
        'unit_price': parseInt(_price.text),
        'shelf_life_days': parseInt(_shelfLife.text),
        'active': _active,
      });
      if (!mounted) return;
      showSuccess(context, context.l10n.productSaved);
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
    String? required(String? text) => (text ?? '').trim().isEmpty ? l10n.fieldRequired : null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<ProductCategory>(
            segments: [
              for (final category in ProductCategory.values)
                ButtonSegment(value: category, label: Text(l10n.categoryLabel(category))),
            ],
            selected: {_category},
            onSelectionChanged: (selection) => setState(() {
              _category = selection.first;
              if (_category == ProductCategory.bread) _format = ProductFormat.piece;
            }),
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _nameMg, decoration: InputDecoration(labelText: l10n.nameMg), validator: required),
          const SizedBox(height: 12),
          TextFormField(controller: _nameFr, decoration: InputDecoration(labelText: l10n.nameFr), validator: required),
          const SizedBox(height: 12),
          if (_category == ProductCategory.juice) ...[
            SegmentedButton<ProductFormat>(
              segments: [
                ButtonSegment(value: ProductFormat.glass, label: Text(l10n.formatGlass)),
                ButtonSegment(value: ProductFormat.bottle, label: Text(l10n.formatBottle)),
              ],
              selected: {_format == ProductFormat.piece ? ProductFormat.glass : _format},
              onSelectionChanged: (selection) => setState(() => _format = selection.first),
            ),
            const SizedBox(height: 12),
          ],
          AmountField(controller: _price, label: l10n.price),
          const SizedBox(height: 12),
          TextFormField(
            controller: _shelfLife,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.shelfLife, helperText: l10n.shelfLifeHelp),
            validator: (text) => (parseInt(text ?? '') ?? 0) >= 1 ? null : l10n.invalidNumber,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.active),
            value: _active,
            onChanged: (value) => setState(() => _active = value),
          ),
          const SizedBox(height: 12),
          SheetActions(
            onSave: () {
              // Un jus est toujours en verre ou en bouteille.
              if (_category == ProductCategory.juice && _format == ProductFormat.piece) _format = ProductFormat.glass;
              _save();
            },
            saving: _saving,
          ),
        ],
      ),
    );
  }
}
