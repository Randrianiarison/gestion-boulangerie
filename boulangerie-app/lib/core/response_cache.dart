import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Dernières réponses reçues du serveur, pour afficher Accueil, Vente et Production sans connexion.
class ResponseCache {
  const ResponseCache(this._prefs);

  final SharedPreferences _prefs;

  static const _prefix = 'cache:';

  Future<void> write(String key, Map<String, dynamic> data) => _prefs.setString(
        '$_prefix$key',
        jsonEncode({'saved_at': DateTime.now().toIso8601String(), 'data': data}),
      );

  Map<String, dynamic>? read(String key) {
    final raw = _prefs.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      return ((jsonDecode(raw) as Map)['data'] as Map).cast<String, dynamic>();
    } on Object {
      return null;
    }
  }

  /// À la déconnexion : le compte suivant ne doit pas voir les chiffres du précédent.
  Future<void> clear() async {
    for (final key in _prefs.getKeys().where((key) => key.startsWith(_prefix)).toList()) {
      await _prefs.remove(key);
    }
  }
}
