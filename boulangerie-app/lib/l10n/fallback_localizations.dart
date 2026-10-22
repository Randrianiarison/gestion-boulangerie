import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// flutter_localizations ne fournit pas de traductions Material, Cupertino ni
/// Widgets pour le malgache ('mg') : sans délégué pour cette langue, MaterialApp
/// échoue dès qu'on passe en malgache (MaterialLocalizations introuvable).
///
/// Ce délégué répond « oui » pour 'mg' et charge à la place les traductions
/// françaises : boutons du calendrier, « Coller », etc. s'affichent en français,
/// tous les textes de l'appli restent en malgache (fichier app_mg.arb).
class FallbackLocalizationsDelegate<T> extends LocalizationsDelegate<T> {
  const FallbackLocalizationsDelegate(
    this._delegate, {
    this.languageCode = 'mg',
    this.fallback = const Locale('fr'),
  });

  final LocalizationsDelegate<T> _delegate;
  final String languageCode;
  final Locale fallback;

  @override
  bool isSupported(Locale locale) => locale.languageCode == languageCode;

  @override
  Future<T> load(Locale locale) => _delegate.load(fallback);

  @override
  bool shouldReload(covariant LocalizationsDelegate<T> old) => false;
}

const malagasyFallbackDelegates = <LocalizationsDelegate<dynamic>>[
  FallbackLocalizationsDelegate<MaterialLocalizations>(GlobalMaterialLocalizations.delegate),
  FallbackLocalizationsDelegate<CupertinoLocalizations>(GlobalCupertinoLocalizations.delegate),
  FallbackLocalizationsDelegate<WidgetsLocalizations>(GlobalWidgetsLocalizations.delegate),
];
