import 'package:dio/dio.dart';

/// Unified network exception that wraps every possible Dio / HTTP failure.
class NetworkException implements Exception {
  const NetworkException({
    required this.message,
    this.statusCode,
    this.data,
  });

  final String message;
  final int? statusCode;
  final dynamic data;

  /// Factory that converts a raw [DioException] into a [NetworkException].
  factory NetworkException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return const NetworkException(
          message: 'Connection timed out. Please check your internet connection.',
          statusCode: null,
        );

      case DioExceptionType.sendTimeout:
        return const NetworkException(
          message: 'Request timed out while sending data.',
          statusCode: null,
        );

      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          message: 'Server took too long to respond.',
          statusCode: null,
        );

      case DioExceptionType.badCertificate:
        return const NetworkException(
          message: 'SSL certificate error.',
          statusCode: null,
        );

      case DioExceptionType.cancel:
        return const NetworkException(
          message: 'Request was cancelled.',
          statusCode: null,
        );

      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'No internet connection.',
          statusCode: null,
        );

      case DioExceptionType.badResponse:
        return NetworkException._fromStatusCode(error);

      case DioExceptionType.unknown:
        return NetworkException(
          message: error.message ?? 'An unexpected error occurred.',
          statusCode: null,
        );
    }
  }

  factory NetworkException._fromStatusCode(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    // Try to extract a message from the response body
    final serverMessage = _extractMessage(data);

    return switch (statusCode) {
      400 => NetworkException(
          message: serverMessage ?? 'Bad request.',
          statusCode: 400,
          data: data,
        ),
      401 => NetworkException(
          message: serverMessage ?? 'Unauthorized. Please log in again.',
          statusCode: 401,
          data: data,
        ),
      403 => NetworkException(
          message: serverMessage ?? 'You do not have permission to perform this action.',
          statusCode: 403,
          data: data,
        ),
      404 => NetworkException(
          message: serverMessage ?? 'Resource not found.',
          statusCode: 404,
          data: data,
        ),
      409 => NetworkException(
          message: serverMessage ?? 'Conflict – resource already exists.',
          statusCode: 409,
          data: data,
        ),
      422 => NetworkException(
          message: serverMessage ?? 'Validation error.',
          statusCode: 422,
          data: data,
        ),
      500 => NetworkException(
          message: serverMessage ?? 'Internal server error.',
          statusCode: 500,
          data: data,
        ),
      502 => NetworkException(
          message: 'Bad gateway.',
          statusCode: 502,
          data: data,
        ),
      503 => NetworkException(
          message: 'Service unavailable.',
          statusCode: 503,
          data: data,
        ),
      _ => NetworkException(
          message: serverMessage ?? 'Unexpected error (HTTP $statusCode).',
          statusCode: statusCode,
          data: data,
        ),
    };
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return (data['message'] ?? data['error'] ?? data['detail'])?.toString();
    }
    return null;
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() => 'NetworkException(status: $statusCode, message: $message)';
}
