import 'dart:convert';
import 'dart:io';

import 'package:boulangerie_app/app.dart';
import 'package:boulangerie_app/core/settings.dart';
import 'package:boulangerie_app/l10n/fallback_localizations.dart';
import 'package:boulangerie_app/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Set<String> _keys(String path) => (jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>)
    .keys
    .where((key) => !key.startsWith('@'))
    .toSet();

Future<void> _pumpApp(WidgetTester tester, {required String locale}) async {
  SharedPreferences.setMockInitialValues({'locale': locale});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    retry: (retryCount, error) => null,
    child: const BoulangerieApp(),
  ));
  await tester.pumpAndSettle();
}

void main() {
  test('les fichiers ARB malgache et français ont exactement les mêmes clés', () {
    final fr = _keys('lib/l10n/app_fr.arb');
    final mg = _keys('lib/l10n/app_mg.arb');

    expect(mg.difference(fr), isEmpty, reason: 'Clés en trop dans app_mg.arb');
    expect(fr.difference(mg), isEmpty, reason: 'Clés manquantes dans app_mg.arb');
  });

  testWidgets('démarre en malgache sans erreur et change de langue', (tester) async {
    await _pumpApp(tester, locale: 'mg');

    // Pas de session : écran de connexion, en malgache.
    expect(find.text('Hiditra'), findsOneWidget);
    expect(find.text('Kaody PIN'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Français'));
    await tester.pumpAndSettle();

    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Code PIN'), findsOneWidget);

    await tester.tap(find.text('Malagasy'));
    await tester.pumpAndSettle();

    expect(find.text('Hiditra'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le calendrier Material s\'ouvre en malgache (repli sur le français)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('mg'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...malagasyFallbackDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showDatePicker(
              context: context,
              initialDate: DateTime(2026, 10, 22),
              firstDate: DateTime(2026),
              lastDate: DateTime(2027),
            ),
            child: Text(AppLocalizations.of(context).date),
          ),
        ),
      ),
    ));

    expect(find.text('Daty'), findsOneWidget);
    await tester.tap(find.text('Daty'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final material = MaterialLocalizations.of(tester.element(find.byType(DatePickerDialog)));
    expect(material.cancelButtonLabel, 'Annuler');
  });

  testWidgets('sans les délégués de repli, le malgache casse MaterialApp', (tester) async {
    // Flutter signale deux erreurs (langue non prise en charge, puis MaterialLocalizations absent) :
    // on les collecte au lieu de laisser le test échouer.
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = errors.add;

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('mg'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: const Scaffold(body: BackButton()),
    ));
    FlutterError.onError = previousOnError;

    // Le test documente pourquoi FallbackLocalizationsDelegate existe.
    expect(errors.map((error) => error.exceptionAsString()).join('\n'), contains('No MaterialLocalizations found'));
  });
}
