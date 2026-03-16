import 'package:dio/dio.dart';

import '../api_constants.dart';
import '../token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio);

  final Dio _dio;
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await TokenStorage.instance.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final newToken = await _refreshToken();
        if (newToken != null) {
          await TokenStorage.instance.saveAccessToken(newToken);

          // Retry the original request with the new token
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final response = await _dio.fetch(opts);
          handler.resolve(response);
          return;
        }
      } catch (_) {
        await TokenStorage.instance.clearAll();
      } finally {
        _isRefreshing = false;
      }
    }
    handler.next(err);
  }

  Future<String?> _refreshToken() async {
    final refreshToken = await TokenStorage.instance.getRefreshToken();
    if (refreshToken == null) return null;

    final role = await TokenStorage.instance.getUserRole();
    final baseUrl = role == 'admin'
        ? ApiConstants.adminBaseUrl
        : ApiConstants.hospitalBaseUrl;

    final response = await Dio().post(
      '$baseUrl${ApiConstants.refreshToken}',
      data: {'refresh_token': refreshToken},
    );

    return response.data['access_token'] as String?;
  }
}
