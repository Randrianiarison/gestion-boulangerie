import 'package:flutter/material.dart';

/// Couleurs de sens, identiques partout : vert = bon, orange = attention, rouge = problème.
abstract final class AppColors {
  static const crust = Color(0xFFB5651D);
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFE65100);
  static const danger = Color(0xFFC62828);
  static const info = Color(0xFF1565C0);
  static const bread = Color(0xFFB5651D);
  static const juice = Color(0xFF2E7D32);
}

/// Thème à gros boutons et gros texte, pour des utilisateurs peu habitués aux écrans.
ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.crust);
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  const buttonText = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);

  // ThemeData().textTheme n'a pas encore de tailles (ajoutées plus tard par Theme.of) :
  // on part des tailles Material 2021, agrandies de 8 %, puis on reprend les couleurs du thème.
  final textTheme = Typography.englishLike2021.apply(fontSizeFactor: 1.08).merge(base.textTheme);

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: scheme.onPrimaryContainer),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(64, 58), shape: buttonShape, textStyle: buttonText),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(64, 54), shape: buttonShape, textStyle: buttonText),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48), textStyle: buttonText),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    ),
    cardTheme: CardThemeData(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    listTileTheme: const ListTileThemeData(minVerticalPadding: 12),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
