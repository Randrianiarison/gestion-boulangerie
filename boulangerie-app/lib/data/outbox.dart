import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_exception.dart';
import '../core/format.dart';
import '../core/settings.dart';
import '../models/json.dart';
import '../models/stock.dart';
import 'connection.dart';
import 'providers.dart';

enum OutboxKind { sale, production }

enum OutboxStatus { pending, rejected }

/// Une ligne « produit × quantité », avec ce qu'il faut pour l'afficher sans connexion.
typedef OutboxLine = ({int productId, int quantity, int unitPrice, String label});

/// Vente au comptoir ou production, gardée sur le téléphone tant que le serveur ne l'a pas reçue.
///
/// `id` part dans l'en-tête Idempotency-Key : si l'opération est renvoyée alors que le serveur
/// l'avait déjà enregistrée (réponse perdue), elle n'est pas comptée deux fois.
class OutboxOperation {
  const OutboxOperation({
    required this.id,
    required this.kind,
    required this.date,
    required this.lines,
    required this.createdAt,
    this.status = OutboxStatus.pending,
    this.error,
  });

  factory OutboxOperation.create(OutboxKind kind, List<OutboxLine> lines, {DateTime? now}) {
    final at = now ?? DateTime.now();
    return OutboxOperation(id: newOperationId(), kind: kind, date: dateOnly(at), lines: lines, createdAt: at);
  }

  factory OutboxOperation.fromJson(Json json) => OutboxOperation(
        id: json['id'] as String,
        kind: OutboxKind.values.byName(json['kind'] as String),
        date: asDate(json['date']),
        createdAt: DateTime.parse(json['created_at'] as String),
        status: OutboxStatus.values.byName(json['status'] as String),
        error: json['error'] as String?,
        lines: [
          for (final line in json['lines'] as List)
            (
              productId: asInt((line as Map)['product_id']),
              quantity: asInt(line['quantity']),
              unitPrice: asInt(line['unit_price']),
              label: line['label'] as String,
            ),
        ],
      );

  final String id;
  final OutboxKind kind;

  /// Jour de la vente ou de la production : il est gardé même si l'envoi a lieu le lendemain.
  final DateTime date;
  final List<OutboxLine> lines;
  final DateTime createdAt;
  final OutboxStatus status;

  /// Message du serveur quand il a refusé l'opération.
  final String? error;

  bool get isPending => status == OutboxStatus.pending;

  String get path => kind == OutboxKind.sale ? '/sales' : '/production';

  Json get body => {
        kind == OutboxKind.sale ? 'sold_on' : 'produced_on': isoDate(date),
        'items': [for (final line in lines) {'product_id': line.productId, 'quantity': line.quantity}],
      };

  int get total => lines.fold(0, (sum, line) => sum + line.quantity * line.unitPrice);

  OutboxOperation copyWith({required OutboxStatus status, String? error}) => OutboxOperation(
        id: id,
        kind: kind,
        date: date,
        lines: lines,
        createdAt: createdAt,
        status: status,
        error: error,
      );

  Json toJson() => {
        'id': id,
        'kind': kind.name,
        'date': isoDate(date),
        'created_at': createdAt.toIso8601String(),
        'status': status.name,
        'error': error,
        'lines': [
          for (final line in lines)
            {'product_id': line.productId, 'quantity': line.quantity, 'unit_price': line.unitPrice, 'label': line.label},
        ],
      };
}

/// 32 caractères hexadécimaux aléatoires (accepté par le serveur : [A-Za-z0-9-]{8,64}).
String newOperationId() {
  final random = Random.secure();
  return List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

/// Stock du jour vu par le téléphone : celui du serveur, moins les ventes et plus la production
/// pas encore envoyées.
List<StockRow> applyPendingToStock(List<StockRow> rows, Iterable<OutboxOperation> operations, DateTime day) {
  final delta = <int, int>{};
  for (final operation in operations) {
    if (!operation.isPending || operation.date != day) continue;
    final sign = operation.kind == OutboxKind.sale ? -1 : 1;
    for (final line in operation.lines) {
      delta.update(line.productId, (value) => value + sign * line.quantity, ifAbsent: () => sign * line.quantity);
    }
  }
  if (delta.isEmpty) return rows;

  return [
    for (final row in rows)
      StockRow(
        product: row.product,
        available: max(0, row.available + (delta[row.product.id] ?? 0)),
        expiring: row.expiring,
        stale: row.stale,
      ),
  ];
}

enum SubmitOutcome { sent, queued, rejected }

typedef SubmitResult = ({SubmitOutcome outcome, String? error});

final outboxProvider = NotifierProvider<OutboxNotifier, List<OutboxOperation>>(OutboxNotifier.new);

/// File d'attente des ventes et productions faites sans connexion, gardée sur le téléphone.
/// Elle est envoyée dans l'ordre (une vente peut dépendre d'une production en attente) :
/// au retour du réseau, toutes les 30 secondes, ou sur demande.
class OutboxNotifier extends Notifier<List<OutboxOperation>> {
  static const _storageKey = 'outbox';
  static const _retryEvery = Duration(seconds: 30);

  Timer? _timer;
  bool _flushing = false;

  @override
  List<OutboxOperation> build() {
    ref.onDispose(() => _timer?.cancel());
    ref.listen(connectionProvider, (previous, online) {
      if (online && previous == false) flush();
    });

    final operations = _load();
    _schedule(operations);
    return operations;
  }

  /// Envoie tout de suite si possible ; sans réseau, garde l'opération sur le téléphone.
  /// Un refus immédiat du serveur (stock épuisé…) est remonté à l'écran comme avant.
  Future<SubmitResult> submit(OutboxOperation operation) async {
    if (state.any((pending) => pending.isPending)) {
      // D'autres opérations attendent : on garde l'ordre d'envoi.
      _save([...state, operation]);
      await flush();
      final current = state.where((pending) => pending.id == operation.id).firstOrNull;
      if (current == null) return (outcome: SubmitOutcome.sent, error: null);
      return current.isPending
          ? (outcome: SubmitOutcome.queued, error: null)
          : (outcome: SubmitOutcome.rejected, error: current.error);
    }

    try {
      await ref.read(bakeryApiProvider).sendOperation(operation);
      return (outcome: SubmitOutcome.sent, error: null);
    } on ApiException catch (e) {
      if (!e.isConnectivityProblem) rethrow;
      _save([...state, operation]);
      return (outcome: SubmitOutcome.queued, error: null);
    }
  }

  /// Envoie les opérations en attente, dans l'ordre. S'arrête dès que le réseau manque.
  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    var sent = 0;
    try {
      for (final operation in state.where((pending) => pending.isPending).toList()) {
        try {
          await ref.read(bakeryApiProvider).sendOperation(operation);
          _save(state.where((other) => other.id != operation.id).toList());
          sent++;
        } on ApiException catch (e) {
          // Hors ligne ou session expirée : on réessaiera plus tard, sans rien perdre.
          if (e.isConnectivityProblem || e.kind == ApiErrorKind.unauthorized) break;
          _save([
            for (final other in state)
              other.id == operation.id
                  ? other.copyWith(status: OutboxStatus.rejected, error: e.message ?? e.code)
                  : other,
          ]);
        } on Object {
          break;
        }
      }
    } finally {
      _flushing = false;
    }

    if (sent > 0) {
      ref
        ..invalidate(serverStockProvider)
        ..invalidate(dashboardProvider)
        ..invalidate(productionTodayProvider)
        ..invalidate(dayClosingProvider);
    }
  }

  /// Une opération refusée est renvoyée telle quelle (même identifiant), une fois le problème réglé.
  Future<void> retry(String id) async {
    _save([for (final operation in state) operation.id == id ? operation.copyWith(status: OutboxStatus.pending) : operation]);
    await flush();
  }

  void discard(String id) => _save(state.where((operation) => operation.id != id).toList());

  void _save(List<OutboxOperation> operations) {
    state = operations;
    ref.read(sharedPreferencesProvider).setString(_storageKey, jsonEncode([for (final op in operations) op.toJson()]));
    _schedule(operations);
  }

  List<OutboxOperation> _load() {
    final raw = ref.read(sharedPreferencesProvider).getString(_storageKey);
    if (raw == null) return const [];
    try {
      return [for (final json in jsonDecode(raw) as List) OutboxOperation.fromJson((json as Map).cast<String, dynamic>())];
    } on Object {
      return const [];
    }
  }

  void _schedule(List<OutboxOperation> operations) {
    if (operations.any((operation) => operation.isPending)) {
      _timer ??= Timer.periodic(_retryEvery, (_) => flush());
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }
}
