import 'package:dio/dio.dart';

import '../network_exceptions.dart';

/// Converts every [DioException] into a [NetworkException] so callers only
/// ever deal with one error type.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Let the AuthInterceptor handle 401s first; it calls handler.next() itself.
    if (err.response?.statusCode == 401) {
      handler.next(err);
      return;
    }
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: NetworkException.fromDioError(err),
        response: err.response,
        type: err.type,
      ),
    );
  }
}
