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
        final newAccessToken = await _refreshToken();
        if (newAccessToken != null) {
          // Retry the original request with the new access token
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newAccessToken';
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

  /// Calls the refresh endpoint, persists both the new access token and the
  /// rotated refresh token, then returns the new access token.
  ///
  /// Response shape:
  /// ```json
  /// { "success": true, "data": { "access_token": "...", "refresh_token": "..." } }
  /// ```
  Future<String?> _refreshToken() async {
    final storedRefreshToken = await TokenStorage.instance.getRefreshToken();
    if (storedRefreshToken == null) return null;

    final role = await TokenStorage.instance.getUserRole();
    final baseUrl = role == 'admin'
        ? ApiConstants.adminBaseUrl
        : ApiConstants.hospitalBaseUrl;

    final response = await Dio().post(
      '$baseUrl${ApiConstants.refreshToken}',
      data: {'refresh_token': storedRefreshToken},
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    final data = response.data['data'] as Map<String, dynamic>?;
    if (data == null) return null;

    final newAccessToken = data['access_token'] as String?;
    final newRefreshToken = data['refresh_token'] as String?;

    if (newAccessToken != null) {
      await TokenStorage.instance.saveAccessToken(newAccessToken);
    }
    // Save rotated refresh token
    if (newRefreshToken != null) {
      await TokenStorage.instance.saveRefreshToken(newRefreshToken);
    }

    return newAccessToken;
  }
}
