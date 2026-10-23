import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings.dart';
import '../../data/providers.dart';
import '../../models/user.dart';

class AuthState {
  const AuthState({this.token, this.user});

  final String? token;
  final AppUser? user;

  bool get isLoggedIn => token != null && user != null;
}

/// Session : jeton Sanctum et utilisateur, gardés sur le téléphone pour ne pas
/// retaper le PIN à chaque ouverture.
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  @override
  AuthState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (token == null || userJson == null) return const AuthState();

    try {
      return AuthState(token: token, user: AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>));
    } on Object {
      return const AuthState();
    }
  }

  Future<void> login(String phone, String pin) async {
    final result = await ref.read(bakeryApiProvider).login(phone, pin);
    await _save(result.token, result.user);
  }

  /// Relit le profil (rôle changé par l'owner) ; un jeton refusé déconnecte via [expire].
  Future<void> refreshProfile() async {
    final token = state.token;
    if (token == null) return;
    final user = await ref.read(bakeryApiProvider).me();
    await _save(token, user);
  }

  Future<void> logout() async {
    try {
      await ref.read(bakeryApiProvider).logout();
    } on Object {
      // Hors ligne : on oublie quand même la session sur le téléphone.
    }
    await _clear();
  }

  /// Jeton refusé par l'API (401).
  void expire() {
    if (state.isLoggedIn) _clear();
  }

  Future<void> _save(String token, AppUser user) async {
    state = AuthState(token: token, user: user);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> _clear() async {
    state = const AuthState();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    // Les chiffres gardés pour le mode hors ligne ne doivent pas rester visibles au compte suivant.
    await ref.read(responseCacheProvider).clear();
  }
}
