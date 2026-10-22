import 'package:dio/dio.dart';

import '../l10n/gen/app_localizations.dart';

enum ApiErrorKind {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  business,
  tooManyAttempts,
  server,
  badResponse,
  unknown,
}

/// Erreur d'appel à l'API, avec ce qu'il faut pour l'afficher dans la bonne langue.
///
/// Pour les règles métier et la validation, l'API renvoie déjà un message
/// traduit (en-tête Accept-Language) : on l'affiche tel quel. Les erreurs
/// sans réponse du serveur (réseau, délai) sont traduites par l'appli.
class ApiException implements Exception {
  const ApiException(
    this.kind, {
    this.message,
    this.code,
    this.params = const {},
    this.fieldErrors = const {},
  });

  final ApiErrorKind kind;
  final String? message;
  final String? code;
  final Map<String, dynamic> params;
  final Map<String, List<String>> fieldErrors;

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(ApiErrorKind.timeout);
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return const ApiException(ApiErrorKind.network);
      case DioExceptionType.cancel:
        return const ApiException(ApiErrorKind.unknown);
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }

    final response = e.response;
    if (response == null) {
      return const ApiException(ApiErrorKind.network);
    }

    final status = response.statusCode ?? 0;
    final data = response.data;
    if (data is! Map) {
      return ApiException(status >= 500 ? ApiErrorKind.server : ApiErrorKind.badResponse);
    }

    final body = data.cast<String, dynamic>();
    final message = body['message'] as String?;
    final code = body['code'] as String?;
    final params = (body['params'] as Map?)?.cast<String, dynamic>() ?? const {};

    return switch (status) {
      401 => const ApiException(ApiErrorKind.unauthorized, code: 'unauthenticated'),
      403 when code == 'forbidden' => ApiException(ApiErrorKind.forbidden, message: message, code: code),
      404 => ApiException(ApiErrorKind.notFound, message: message, code: code),
      429 => const ApiException(ApiErrorKind.tooManyAttempts),
      422 when code == 'validation' => ApiException(
          ApiErrorKind.validation,
          message: message,
          code: code,
          fieldErrors: _fieldErrors(body['errors']),
        ),
      >= 500 => const ApiException(ApiErrorKind.server),
      _ when message != null => ApiException(ApiErrorKind.business, message: message, code: code, params: params),
      _ => const ApiException(ApiErrorKind.unknown),
    };
  }

  static Map<String, List<String>> _fieldErrors(Object? errors) {
    if (errors is! Map) return const {};
    return errors.map((key, value) => MapEntry(key.toString(), (value as List).map((e) => e.toString()).toList()));
  }

  /// Message à montrer à l'utilisateur, dans la langue de l'appli.
  String describe(AppLocalizations l10n) => switch (kind) {
        ApiErrorKind.network => l10n.errorNetwork,
        ApiErrorKind.timeout => l10n.errorTimeout,
        ApiErrorKind.unauthorized => l10n.errorUnauthorized,
        ApiErrorKind.forbidden => message ?? l10n.errorForbidden,
        ApiErrorKind.notFound => l10n.errorNotFound,
        ApiErrorKind.tooManyAttempts => l10n.errorTooManyAttempts,
        ApiErrorKind.server => l10n.errorServer,
        ApiErrorKind.badResponse => l10n.errorBadResponse,
        ApiErrorKind.validation || ApiErrorKind.business => message ?? l10n.errorUnknown,
        ApiErrorKind.unknown => l10n.errorUnknown,
      };

  @override
  String toString() => 'ApiException($kind, $code, $message)';
}

/// Texte d'erreur pour n'importe quelle exception (une réponse illisible devient « réponse inattendue »).
String errorText(AppLocalizations l10n, Object error) {
  if (error is ApiException) return error.describe(l10n);
  if (error is TypeError || error is FormatException) return l10n.errorBadResponse;
  return l10n.errorUnknown;
}
