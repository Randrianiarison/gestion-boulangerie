import '../core/format.dart';

typedef Json = Map<String, dynamic>;

/// Laravel encode 0.0 en 0 : on lit toujours les nombres via `num`.
int asInt(Object? value) => (value as num).toInt();

double asDouble(Object? value) => (value as num).toDouble();

DateTime asDate(Object? value) => parseIsoDate(value as String);

DateTime? asDateOrNull(Object? value) => value == null ? null : parseIsoDate(value as String);

List<T> asList<T>(Object? value, T Function(Json json) fromJson) =>
    (value as List? ?? const []).map((item) => fromJson((item as Map).cast<String, dynamic>())).toList();

Json asJson(Object? value) => (value as Map).cast<String, dynamic>();

Map<String, int> asIntMap(Object? value) =>
    (value as Map? ?? const {}).map((key, amount) => MapEntry(key.toString(), asInt(amount)));
