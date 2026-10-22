import 'package:boulangerie_app/core/api_exception.dart';
import 'package:boulangerie_app/l10n/gen/app_localizations_fr.dart';
import 'package:boulangerie_app/l10n/gen/app_localizations_mg.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _response(int status, Object? data) {
  final options = RequestOptions(path: '/sales');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  final fr = AppLocalizationsFr();
  final mg = AppLocalizationsMg();

  test('sans réseau : message traduit par l\'appli', () {
    final error = ApiException.fromDio(DioException(
      requestOptions: RequestOptions(path: '/login'),
      type: DioExceptionType.connectionError,
    ));

    expect(error.kind, ApiErrorKind.network);
    expect(error.describe(fr), fr.errorNetwork);
    expect(error.describe(mg), mg.errorNetwork);
    expect(error.describe(mg), isNot(error.describe(fr)));
  });

  test('délai dépassé', () {
    final error = ApiException.fromDio(DioException(
      requestOptions: RequestOptions(path: '/login'),
      type: DioExceptionType.receiveTimeout,
    ));
    expect(error.kind, ApiErrorKind.timeout);
  });

  test('règle métier : on affiche le message déjà traduit par l\'API', () {
    final error = ApiException.fromDio(_response(422, {
      'message': 'Tsy ampy ny Mofo lava : 3 no misy, 5 no ilaina.',
      'code': 'insufficient_stock',
      'params': {'available': 3, 'requested': 5},
    }));

    expect(error.kind, ApiErrorKind.business);
    expect(error.code, 'insufficient_stock');
    expect(error.params['available'], 3);
    expect(error.describe(fr), 'Tsy ampy ny Mofo lava : 3 no misy, 5 no ilaina.');
  });

  test('validation : erreurs par champ', () {
    final error = ApiException.fromDio(_response(422, {
      'message': 'Le champ code PIN est obligatoire.',
      'code': 'validation',
      'errors': {
        'pin': ['Le champ code PIN est obligatoire.'],
      },
    }));

    expect(error.kind, ApiErrorKind.validation);
    expect(error.fieldErrors['pin'], ['Le champ code PIN est obligatoire.']);
  });

  test('statuts HTTP', () {
    expect(ApiException.fromDio(_response(401, {'code': 'unauthenticated'})).kind, ApiErrorKind.unauthorized);
    expect(ApiException.fromDio(_response(403, {'code': 'forbidden', 'message': 'x'})).kind, ApiErrorKind.forbidden);
    expect(ApiException.fromDio(_response(403, {'code': 'account_disabled', 'message': 'x'})).kind, ApiErrorKind.business);
    expect(ApiException.fromDio(_response(429, {'code': 'too_many_attempts'})).kind, ApiErrorKind.tooManyAttempts);
    expect(ApiException.fromDio(_response(500, {'message': 'Server Error'})).kind, ApiErrorKind.server);
  });

  test('une page HTML (mauvaise adresse de serveur) donne « réponse inattendue »', () {
    final error = ApiException.fromDio(_response(404, '<html>Not found</html>'));
    expect(error.kind, ApiErrorKind.badResponse);
    expect(errorText(fr, error), fr.errorBadResponse);
  });
}
