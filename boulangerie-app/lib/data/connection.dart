import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// true tant que le serveur répond. Le client HTTP le signale à chaque appel.
///
/// Hors ligne, les écrans lisent leurs données en cache sans attendre la fin du délai réseau,
/// et un essai léger est fait toutes les 15 secondes. Dès que le serveur répond, les écrans se
/// rechargent et les opérations en attente partent (voir OutboxNotifier).
final connectionProvider = NotifierProvider<ConnectionNotifier, bool>(ConnectionNotifier.new);

class ConnectionNotifier extends Notifier<bool> {
  static const _probeEvery = Duration(seconds: 15);

  Timer? _probe;

  @override
  bool build() {
    ref.onDispose(() => _probe?.cancel());
    return true;
  }

  void report(bool reachable) {
    if (reachable == state) return;
    state = reachable;

    if (reachable) {
      _probe?.cancel();
      _probe = null;
      ref
        ..invalidate(dashboardProvider)
        ..invalidate(serverStockProvider)
        ..invalidate(activeProductsProvider)
        ..invalidate(productionTodayProvider);
    } else {
      _probe ??= Timer.periodic(_probeEvery, (_) => check());
    }
  }

  /// Appel léger au serveur ; le client HTTP met l'état à jour selon la réponse.
  Future<void> check() async {
    try {
      await ref.read(bakeryApiProvider).ping();
    } on Object {
      // Toujours injoignable : report(false) a déjà été appelé par le client.
    }
  }
}
