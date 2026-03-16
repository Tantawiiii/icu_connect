import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'api_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

/// The two user roles that map to separate API base URLs.
enum UserRole {
  admin,    // → /api/v1/admin
  hospital, // → /api/v1/hospital
}

extension UserRoleX on UserRole {
  String get baseUrl => switch (this) {
        UserRole.admin => ApiConstants.adminBaseUrl,
        UserRole.hospital => ApiConstants.hospitalBaseUrl,
      };

  String get name => switch (this) {
        UserRole.admin => 'admin',
        UserRole.hospital => 'hospital',
      };
}

/// Factory that vends a fully configured [Dio] instance per [UserRole].
///
/// Each role gets its own singleton Dio instance with the correct base URL.
/// Interceptors are applied in order:
///   1. [AuthInterceptor]  – injects Bearer token, handles silent refresh
///   2. [ErrorInterceptor] – maps [DioException] → [NetworkException]
///   3. [PrettyDioLogger]  – prints requests/responses in debug mode only
class ApiClient {
  ApiClient._();

  static Dio? _adminDio;
  static Dio? _hospitalDio;

  /// Returns the singleton [Dio] instance for the given [role].
  static Dio client(UserRole role) {
    return switch (role) {
      UserRole.admin => _adminDio ??= _build(role),
      UserRole.hospital => _hospitalDio ??= _build(role),
    };
  }

  static Dio _build(UserRole role) {
    final dio = Dio(
      BaseOptions(
        baseUrl: role.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        responseType: ResponseType.json,
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(dio),
      ErrorInterceptor(),
      // Logger is only active in debug/profile mode
      if (const bool.fromEnvironment('dart.vm.product') == false)
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
        ),
    ]);

    return dio;
  }

  /// Call this on logout to reset both clients (clears cached tokens from headers).
  static void reset() {
    _adminDio = null;
    _hospitalDio = null;
  }
}
