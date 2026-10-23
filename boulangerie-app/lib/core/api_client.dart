import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Client HTTP de l'API : URL, jeton et langue sont relus à chaque requête,
/// pour suivre les changements faits dans les réglages sans recréer le client.
class ApiClient {
  ApiClient({
    required String Function() baseUrl,
    required String? Function() token,
    required String Function() languageCode,
    required void Function() onUnauthorized,
    void Function(bool reachable)? onReachability,
    Dio? dio,
  })  : _onUnauthorized = onUnauthorized,
        _onReachability = onReachability,
        _dio = dio ?? Dio() {
    _dio.options
      ..connectTimeout = const Duration(seconds: 10)
      ..sendTimeout = const Duration(seconds: 20)
      ..receiveTimeout = const Duration(seconds: 30)
      ..headers['Accept'] = 'application/json';

    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      options.baseUrl = baseUrl();
      options.headers['Accept-Language'] = languageCode();
      final bearer = token();
      if (bearer != null) {
        options.headers['Authorization'] = 'Bearer $bearer';
      }
      handler.next(options);
    }));
  }

  final Dio _dio;
  final void Function() _onUnauthorized;

  /// Prévenu à chaque appel : le serveur a-t-il répondu (même par une erreur) ou est-il injoignable ?
  final void Function(bool reachable)? _onReachability;

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: _clean(query)));

  Future<Map<String, dynamic>> post(String path, [Object? data, Map<String, String>? headers]) =>
      _send(() => _dio.post<dynamic>(path, data: data, options: headers == null ? null : Options(headers: headers)));

  Future<Map<String, dynamic>> put(String path, [Object? data]) => _send(() => _dio.put<dynamic>(path, data: data));

  Future<Map<String, dynamic>> patch(String path, [Object? data]) => _send(() => _dio.patch<dynamic>(path, data: data));

  Future<Map<String, dynamic>> delete(String path) => _send(() => _dio.delete<dynamic>(path));

  Future<Map<String, dynamic>> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final data = (await request()).data;
      _onReachability?.call(true);
      if (data is Map) return data.cast<String, dynamic>();
      // 204 No Content : rien à lire. Une page HTML (mauvaise adresse) : réponse inattendue.
      if (data == null || data == '') return const {};
      throw const ApiException(ApiErrorKind.badResponse);
    } on DioException catch (e) {
      final error = ApiException.fromDio(e);
      _onReachability?.call(!error.isConnectivityProblem);
      if (error.kind == ApiErrorKind.unauthorized) _onUnauthorized();
      throw error;
    }
  }

  static Map<String, dynamic>? _clean(Map<String, dynamic>? query) =>
      query == null ? null : (Map.of(query)..removeWhere((_, value) => value == null));
}
