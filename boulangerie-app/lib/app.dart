import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/settings.dart';
import 'core/theme.dart';
import 'l10n/fallback_localizations.dart';
import 'l10n/gen/app_localizations.dart';
import 'router.dart';
import 'widgets/offline_banner.dart';

class BoulangerieApp extends ConsumerWidget {
  const BoulangerieApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: ref.watch(localeProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        // Avant les délégués globaux : Material/Cupertino/Widgets en français quand l'appli est en malgache.
        ...malagasyFallbackDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
      // Hors ligne ou opérations en attente : bandeau visible sur tous les écrans.
      builder: (context, child) => OfflineBanner(child: child ?? const SizedBox.shrink()),
    );
  }
}
