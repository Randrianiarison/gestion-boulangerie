import 'json.dart';

enum ProductCategory { bread, juice }

enum ProductFormat { piece, glass, bottle }

enum SaleSource { counter, closing }

enum WasteReason { expired, damaged, other }

class Product {
  const Product({
    required this.id,
    required this.category,
    required this.nameFr,
    required this.nameMg,
    required this.format,
    required this.unitPrice,
    required this.shelfLifeDays,
    required this.active,
  });

  factory Product.fromJson(Json json) => Product(
        id: asInt(json['id']),
        category: ProductCategory.values.byName(json['category'] as String),
        nameFr: json['name_fr'] as String,
        nameMg: json['name_mg'] as String,
        format: ProductFormat.values.byName(json['format'] as String),
        unitPrice: asInt(json['unit_price']),
        shelfLifeDays: asInt(json['shelf_life_days']),
        active: json['active'] as bool,
      );

  final int id;
  final ProductCategory category;
  final String nameFr;
  final String nameMg;
  final ProductFormat format;
  final int unitPrice;
  final int shelfLifeDays;
  final bool active;

  String name(String languageCode) => languageCode == 'mg' ? nameMg : nameFr;
}

/// Disponible d'un produit à une date (dont `expiring` expire ce jour, `stale` déjà expiré non clôturé).
class StockRow {
  const StockRow({required this.product, required this.available, required this.expiring, required this.stale});

  factory StockRow.fromJson(Json json) => StockRow(
        product: Product.fromJson(asJson(json['product'])),
        available: asInt(json['available']),
        expiring: asInt(json['expiring']),
        stale: asInt(json['stale']),
      );

  final Product product;
  final int available;
  final int expiring;
  final int stale;

  /// Aperçu de la clôture : vendu = disponible - restant ; les lots qui expirent sont vendus en premier (FIFO).
  int soldFor(int remaining) => available - remaining;

  int unsoldFor(int remaining) {
    final notSoldFromExpiring = expiring - soldFor(remaining);
    return (notSoldFromExpiring > 0 ? notSoldFromExpiring : 0) + stale;
  }
}

class StockLot {
  const StockLot({
    required this.id,
    required this.product,
    required this.producedOn,
    required this.expiresOn,
    required this.quantityProduced,
    required this.quantityRemaining,
    required this.untouched,
  });

  factory StockLot.fromJson(Json json) => StockLot(
        id: asInt(json['id']),
        product: json['product'] == null ? null : Product.fromJson(asJson(json['product'])),
        producedOn: asDate(json['produced_on']),
        expiresOn: asDate(json['expires_on']),
        quantityProduced: asInt(json['quantity_produced']),
        quantityRemaining: asInt(json['quantity_remaining']),
        untouched: json['untouched'] as bool,
      );

  final int id;
  final Product? product;
  final DateTime producedOn;
  final DateTime expiresOn;
  final int quantityProduced;
  final int quantityRemaining;
  final bool untouched;
}

class Sale {
  const Sale({
    required this.id,
    required this.product,
    required this.soldOn,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.source,
  });

  factory Sale.fromJson(Json json) => Sale(
        id: asInt(json['id']),
        product: json['product'] == null ? null : Product.fromJson(asJson(json['product'])),
        soldOn: asDate(json['sold_on']),
        quantity: asInt(json['quantity']),
        unitPrice: asInt(json['unit_price']),
        total: asInt(json['total']),
        source: SaleSource.values.byName(json['source'] as String),
      );

  final int id;
  final Product? product;
  final DateTime soldOn;
  final int quantity;
  final int unitPrice;
  final int total;
  final SaleSource source;
}

class WasteRecord {
  const WasteRecord({
    required this.id,
    required this.product,
    required this.date,
    required this.quantity,
    required this.reason,
    required this.lostValue,
    required this.recoveredAmount,
    required this.note,
  });

  factory WasteRecord.fromJson(Json json) => WasteRecord(
        id: asInt(json['id']),
        product: json['product'] == null ? null : Product.fromJson(asJson(json['product'])),
        date: asDate(json['date']),
        quantity: asInt(json['quantity']),
        reason: WasteReason.values.byName(json['reason'] as String),
        lostValue: asInt(json['lost_value']),
        recoveredAmount: asInt(json['recovered_amount']),
        note: json['note'] as String?,
      );

  final int id;
  final Product? product;
  final DateTime date;
  final int quantity;
  final WasteReason reason;
  final int lostValue;
  final int recoveredAmount;
  final String? note;
}

class ClosingSummary {
  const ClosingSummary({
    required this.automatic,
    required this.closedBy,
    required this.salesTotal,
    required this.wasteQuantity,
    required this.wasteValue,
    required this.recoveredTotal,
    required this.sales,
    required this.wasteRecords,
  });

  factory ClosingSummary.fromJson(Json json) => ClosingSummary(
        automatic: json['mode'] == 'automatic',
        closedBy: json['closed_by'] as String?,
        salesTotal: asInt(json['sales_total']),
        wasteQuantity: asInt(json['waste_quantity']),
        wasteValue: asInt(json['waste_value']),
        recoveredTotal: asInt(json['recovered_total']),
        sales: asList(json['sales'], Sale.fromJson),
        wasteRecords: asList(json['waste_records'], WasteRecord.fromJson),
      );

  final bool automatic;
  final String? closedBy;
  final int salesTotal;
  final int wasteQuantity;
  final int wasteValue;
  final int recoveredTotal;
  final List<Sale> sales;
  final List<WasteRecord> wasteRecords;
}

/// GET /day-closing/{date} : à compter, ou résumé si déjà clôturée.
class DayClosingState {
  const DayClosingState({
    required this.date,
    required this.closed,
    required this.canClose,
    required this.blockedReason,
    required this.items,
    required this.closing,
    required this.canCancel,
  });

  factory DayClosingState.fromJson(Json json) => DayClosingState(
        date: asDate(json['date']),
        closed: json['closed'] as bool,
        canClose: json['can_close'] as bool,
        blockedReason: json['blocked_reason'] as String?,
        items: asList(json['items'], StockRow.fromJson),
        closing: json['closing'] == null ? null : ClosingSummary.fromJson(asJson(json['closing'])),
        canCancel: json['can_cancel'] as bool,
      );

  final DateTime date;
  final bool closed;
  final bool canClose;
  final String? blockedReason;
  final List<StockRow> items;
  final ClosingSummary? closing;
  final bool canCancel;
}
