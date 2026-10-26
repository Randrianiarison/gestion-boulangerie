import 'package:boulangerie_app/core/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const nbsp = ' ';

  test('les montants s\'affichent « 12 500 Ar »', () {
    expect(formatMoney(12500), '12${nbsp}500${nbsp}Ar');
    expect(formatMoney(800), '800${nbsp}Ar');
    expect(formatMoney(1250000), '1${nbsp}250${nbsp}000${nbsp}Ar');
    expect(formatMoney(-25000), '-25${nbsp}000${nbsp}Ar');
    expect(formatMoney(0), '0${nbsp}Ar');
  });

  test('les quantités utilisent la virgule et sans zéros inutiles', () {
    expect(formatQuantity(22.5), '22,5');
    expect(formatQuantity(3.0), '3');
    expect(formatQuantity(1500.25), '1${nbsp}500,25');
    expect(formatQuantity(2.48, decimals: 1), '2,5');
  });

  test('la contenance des bouteilles s\'affiche en cl ou en L', () {
    expect(formatVolume(330), '33${nbsp}cl');
    expect(formatVolume(500), '50${nbsp}cl');
    expect(formatVolume(1000), '1${nbsp}L');
    expect(formatVolume(1500), '1,5${nbsp}L');
    expect(formatVolume(125), '125${nbsp}ml');
  });

  test('la saisie accepte la virgule ou le point', () {
    expect(parseDecimal('2,5'), 2.5);
    expect(parseDecimal('2.5'), 2.5);
    expect(parseDecimal('abc'), isNull);
    expect(parseInt('12 500'), 12500);
  });

  test('dates ISO', () {
    expect(isoDate(DateTime(2026, 3, 7)), '2026-03-07');
    expect(isoMonth(DateTime(2026, 3, 7)), '2026-03');
    expect(parseIsoDate('2026-10-22'), DateTime(2026, 10, 22));
    expect(parseIsoDate('2026-10'), DateTime(2026, 10));
  });

  test('dates en toutes lettres en français et en malgache', () {
    final day = DateTime(2026, 10, 22); // un jeudi
    expect(const DateLabels('fr').long(day), 'jeudi 22 octobre 2026');
    expect(const DateLabels('mg').long(day), 'Alakamisy 22 Oktobra 2026');
    expect(const DateLabels('fr').monthYear(day), 'Octobre 2026');
    expect(const DateLabels('mg').dayMonth(day), '22 Okt');
    expect(const DateLabels('fr').short(day), '22/10/2026');
  });

  test('abréviations malgaches des jours toutes différentes', () {
    final week = [for (var i = 0; i < 7; i++) DateTime(2026, 10, 19 + i)];
    final labels = week.map(const DateLabels('mg').shortWeekday).toSet();
    expect(labels, hasLength(7));
  });
}
