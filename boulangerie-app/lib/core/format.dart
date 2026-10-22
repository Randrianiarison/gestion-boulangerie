import 'package:flutter/widgets.dart';

const _nbsp = ' ';

/// « 12 500 Ar » : Ariary entiers, espaces insécables entre milliers.
String formatMoney(int amount) => '${formatInt(amount)}${_nbsp}Ar';

String formatInt(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(_nbsp);
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Quantité avec virgule décimale (« 22,5 »), sans zéros inutiles.
String formatQuantity(num value, {int decimals = 3}) {
  final rounded = double.parse(value.toStringAsFixed(decimals));
  if (rounded == rounded.roundToDouble()) return formatInt(rounded.round());

  final parts = rounded.toStringAsFixed(decimals).replaceAll(RegExp(r'0+$'), '').split('.');
  return '${formatInt(int.parse(parts[0]))},${parts[1]}';
}

/// Saisie utilisateur « 2,5 » ou « 2.5 » → 2.5 (null si invalide).
double? parseDecimal(String input) => double.tryParse(input.trim().replaceAll(' ', '').replaceAll(',', '.'));

/// Saisie d'un montant ou d'une quantité entière (espaces tolérés).
int? parseInt(String input) => int.tryParse(input.replaceAll(RegExp(r'[\s ]'), ''));

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime today() => dateOnly(DateTime.now());

String isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String isoMonth(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}';

DateTime parseIsoDate(String value) {
  final parts = value.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts.length > 2 ? parts[2] : 1);
}

/// Dates en toutes lettres. Le paquet intl ne connaît pas le malgache : noms écrits ici.
class DateLabels {
  const DateLabels(this.languageCode);

  factory DateLabels.of(BuildContext context) => DateLabels(Localizations.localeOf(context).languageCode);

  final String languageCode;

  bool get _mg => languageCode == 'mg';

  static const _monthsFr = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];
  static const _monthsMg = [
    'Janoary', 'Febroary', 'Martsa', 'Aprily', 'Mey', 'Jona',
    'Jolay', 'Aogositra', 'Septambra', 'Oktobra', 'Novambra', 'Desambra',
  ];
  static const _shortMonthsFr = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];
  static const _shortMonthsMg = ['Jan', 'Feb', 'Mar', 'Apr', 'Mey', 'Jon', 'Jol', 'Aog', 'Sep', 'Okt', 'Nov', 'Des'];
  static const _weekdaysFr = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
  static const _weekdaysMg = ['Alatsinainy', 'Talata', 'Alarobia', 'Alakamisy', 'Zoma', 'Sabotsy', 'Alahady'];
  static const _shortWeekdaysFr = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
  // Quatre jours commencent par « Ala » : abréviations distinctes.
  static const _shortWeekdaysMg = ['Alts', 'Tal', 'Alrb', 'Alkm', 'Zom', 'Sab', 'Alhd'];

  /// 22/10/2026
  String short(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  /// jeudi 22 octobre 2026 · Alakamisy 22 Oktobra 2026
  String long(DateTime date) => '${weekday(date)} ${date.day} ${month(date)} ${date.year}';

  /// 22 oct. · 22 Okt
  String dayMonth(DateTime date) => '${date.day} ${(_mg ? _shortMonthsMg : _shortMonthsFr)[date.month - 1]}';

  /// Octobre 2026 · Oktobra 2026
  String monthYear(DateTime date) {
    final name = month(date);
    return '${name[0].toUpperCase()}${name.substring(1)} ${date.year}';
  }

  String month(DateTime date) => (_mg ? _monthsMg : _monthsFr)[date.month - 1];

  String weekday(DateTime date) => (_mg ? _weekdaysMg : _weekdaysFr)[date.weekday - 1];

  String shortWeekday(DateTime date) => (_mg ? _shortWeekdaysMg : _shortWeekdaysFr)[date.weekday - 1];
}
