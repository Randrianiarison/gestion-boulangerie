import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Surchargé dans main() une fois SharedPreferences chargé.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider doit être surchargé dans main()'),
);

/// Adresse de l'API par défaut. Sur l'émulateur Android, 10.0.2.2 est la machine hôte.
/// Autre valeur : `flutter run --dart-define=API_URL=http://192.168.1.20:8000/api`,
/// ou à tout moment depuis l'écran de connexion / les réglages.
const defaultApiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000/api');

const supportedLanguageCodes = ['mg', 'fr'];

/// Langue choisie, mémorisée sur le téléphone (malgache par défaut).
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
  static const _key = 'locale';

  @override
  Locale build() {
    final code = ref.read(sharedPreferencesProvider).getString(_key);
    return Locale(supportedLanguageCodes.contains(code) ? code! : 'mg');
  }

  Future<void> change(Locale locale) async {
    state = locale;
    await ref.read(sharedPreferencesProvider).setString(_key, locale.languageCode);
  }
}

final apiUrlProvider = NotifierProvider<ApiUrlNotifier, String>(ApiUrlNotifier.new);

class ApiUrlNotifier extends Notifier<String> {
  static const _key = 'api_url';

  @override
  String build() => ref.read(sharedPreferencesProvider).getString(_key) ?? defaultApiUrl;

  Future<void> change(String url) async {
    final cleaned = url.trim().replaceAll(RegExp(r'/+$'), '');
    state = cleaned;
    await ref.read(sharedPreferencesProvider).setString(_key, cleaned);
  }
}
