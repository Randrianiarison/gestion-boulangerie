import 'package:boulangerie_app/data/outbox.dart';
import 'package:boulangerie_app/models/stock.dart';
import 'package:flutter_test/flutter_test.dart';

StockRow _row(int id, int available) => StockRow(
      product: Product(
        id: id,
        category: ProductCategory.bread,
        nameFr: 'Pain $id',
        nameMg: 'Mofo $id',
        format: ProductFormat.piece,
        unitPrice: 800,
        shelfLifeDays: 1,
        active: true,
      ),
      available: available,
      expiring: available,
      stale: 0,
    );

void main() {
  final now = DateTime(2026, 10, 22, 14, 5);
  final day = DateTime(2026, 10, 22);

  test('une vente hors ligne garde son jour et part avec un identifiant accepté par le serveur', () {
    final sale = OutboxOperation.create(
      OutboxKind.sale,
      [(productId: 1, quantity: 2, unitPrice: 800, label: 'Baguette')],
      now: now,
    );

    expect(sale.id, matches(RegExp(r'^[A-Za-z0-9-]{8,64}$')));
    expect(sale.path, '/sales');
    expect(sale.body, {
      'sold_on': '2026-10-22',
      'items': [
        {'product_id': 1, 'quantity': 2},
      ],
    });
    expect(sale.total, 1600);
    expect(OutboxOperation.create(OutboxKind.sale, const [], now: now).id, isNot(sale.id));
  });

  test('la production part sur /production avec sa date', () {
    final production = OutboxOperation.create(
      OutboxKind.production,
      [(productId: 1, quantity: 50, unitPrice: 800, label: 'Baguette')],
      now: now,
    );

    expect(production.path, '/production');
    expect(production.body['produced_on'], '2026-10-22');
  });

  test('une opération survit au redémarrage du téléphone (JSON)', () {
    final sale = OutboxOperation.create(
      OutboxKind.sale,
      [(productId: 4, quantity: 1, unitPrice: 4000, label: "Jus d'avocat · bouteille")],
      now: now,
    ).copyWith(status: OutboxStatus.rejected, error: 'Stock insuffisant');

    final restored = OutboxOperation.fromJson(sale.toJson());

    expect(restored.id, sale.id);
    expect(restored.kind, OutboxKind.sale);
    expect(restored.date, day);
    expect(restored.createdAt, now);
    expect(restored.status, OutboxStatus.rejected);
    expect(restored.error, 'Stock insuffisant');
    expect(restored.lines.single.label, "Jus d'avocat · bouteille");
    expect(restored.total, 4000);
  });

  test('le stock affiché tient compte des ventes et productions pas encore envoyées', () {
    final rows = [_row(1, 45), _row(2, 3)];
    final operations = [
      OutboxOperation.create(OutboxKind.sale, [(productId: 1, quantity: 5, unitPrice: 800, label: 'Pain 1')], now: now),
      OutboxOperation.create(OutboxKind.production, [(productId: 2, quantity: 20, unitPrice: 800, label: 'Pain 2')], now: now),
      // Une vente refusée n'a pas eu lieu côté serveur : elle ne compte pas.
      OutboxOperation.create(OutboxKind.sale, [(productId: 1, quantity: 9, unitPrice: 800, label: 'Pain 1')], now: now)
          .copyWith(status: OutboxStatus.rejected),
      // Une vente d'hier ne touche pas au stock du jour.
      OutboxOperation.create(OutboxKind.sale, [(productId: 2, quantity: 1, unitPrice: 800, label: 'Pain 2')],
          now: now.subtract(const Duration(days: 1))),
      // Jamais de stock négatif à l'écran.
      OutboxOperation.create(OutboxKind.sale, [(productId: 2, quantity: 50, unitPrice: 800, label: 'Pain 2')], now: now),
    ];

    final adjusted = applyPendingToStock(rows, operations, day);

    expect(adjusted[0].available, 40); // 45 - 5
    expect(adjusted[1].available, 0); // 3 + 20 - 50, ramené à 0
    expect(applyPendingToStock(rows, const [], day), same(rows));
  });
}
