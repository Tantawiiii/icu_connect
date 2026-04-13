import 'package:dio/dio.dart';

import '../api_client.dart';
import '../cancel_token_manager.dart';
import '../network_exceptions.dart';

/// Base class for all API service classes.
///
/// Provides convenience wrappers around Dio's HTTP methods that:
///   - Automatically use the correct [Dio] instance for the current [role]
///   - Support per-request [CancelToken]s via [CancelTokenManager]
///   - Unwrap successful responses or throw [NetworkException]
abstract class BaseApiService {
  const BaseApiService(this.role);

  final UserRole role;

  Dio get _dio => ApiClient.client(role);

  // ── GET ───────────────────────────────────────────────────────────────────
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? cancelTag,
    Options? options,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        cancelToken: _token(cancelTag),
        options: options,
      );
      return _unwrap(response);
    } on DioException catch (e) {
      throw _toNetworkException(e);
    }
  }

  // ── POST ──────────────────────────────────────────────────────────────────
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? cancelTag,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: _token(cancelTag),
        options: options,
      );
      return _unwrap(response);
    } on DioException catch (e) {
      throw _toNetworkException(e);
    }
  }

  // ── PUT ───────────────────────────────────────────────────────────────────
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? cancelTag,
    Options? options,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: _token(cancelTag),
        options: options,
      );
      return _unwrap(response);
    } on DioException catch (e) {
      throw _toNetworkException(e);
    }
  }

  // ── PATCH ─────────────────────────────────────────────────────────────────
  Future<T> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? cancelTag,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: _token(cancelTag),
        options: options,
      );
      return _unwrap(response);
    } on DioException catch (e) {
      throw _toNetworkException(e);
    }
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? cancelTag,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: _token(cancelTag),
        options: options,
      );
      return _unwrap(response);
    } on DioException catch (e) {
      throw _toNetworkException(e);
    }
  }

  /// DELETE when the server may return no JSON body (e.g. 204 No Content).
  Future<void> deleteWithoutBody(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? cancelTag,
    Options? options,
  }) async {
    try {
      await _dio.delete<void>(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: _token(cancelTag),
        options: options,
      );
    } on DioException catch (e) {
      throw _toNetworkException(e);
    }
  }

  // ── Upload (multipart) ────────────────────────────────────────────────────
  Future<T> upload<T>(
    String path,
    FormData formData, {
    String? cancelTag,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: formData,
        cancelToken: _token(cancelTag),
        onSendProgress: onSendProgress,
        options: Options(contentType: 'multipart/form-data'),
      );
      return _unwrap(response);
    } on DioException catch (e) {
      throw _toNetworkException(e);
    }
  }

  /// Multipart PUT (e.g. admissions with new radiology files).
  Future<T> uploadPut<T>(
    String path,
    FormData formData, {
    String? cancelTag,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: formData,
        cancelToken: _token(cancelTag),
        onSendProgress: onSendProgress,
        options: Options(contentType: 'multipart/form-data'),
      );
      return _unwrap(response);
    } on DioException catch (e) {
      throw _toNetworkException(e);
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────
  CancelToken? _token(String? tag) =>
      tag != null ? CancelTokenManager.instance.getToken(tag) : null;

  T _unwrap<T>(Response<T> response) {
    if (response.data == null) {
      throw const NetworkException(message: 'Empty response body.');
    }
    return response.data as T;
  }

  NetworkException _toNetworkException(DioException e) {
    if (e.error is NetworkException) return e.error as NetworkException;
    return NetworkException.fromDioError(e);
  }
}
