import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'api_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

/// The two user roles that map to separate API base URLs.
enum UserRole {
  admin, // → /api/v1/admin
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

class ApiClient {
  ApiClient._();

  static Dio? _adminDio;
  static Dio? _hospitalDio;
  static Dio? _passwordDio;

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

  /// Dio for `/api/v1/password/*` (forgot OTP, verify, reset). No auth header.
  static Dio passwordClient() {
    return _passwordDio ??= _buildPassword();
  }

  static Dio _buildPassword() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.passwordBaseUrl,
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
      ErrorInterceptor(),
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

  /// Returns role from persisted value and defaults safely to hospital.
  static UserRole roleFromStoredValue(String? value) {
    return switch (value) {
      'admin' => UserRole.admin,
      'hospital' => UserRole.hospital,
      _ => UserRole.hospital,
    };
  }

  /// Resolves a role from a given base URL.
  static UserRole? roleFromBaseUrl(String baseUrl) {
    final normalized = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (normalized == ApiConstants.adminBaseUrl) return UserRole.admin;
    if (normalized == ApiConstants.hospitalBaseUrl) return UserRole.hospital;
    return null;
  }

  /// Checks that a role is using its expected base URL.
  static bool isValidBaseUrlForRole(UserRole role, String baseUrl) {
    final normalized = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return normalized == role.baseUrl;
  }

  /// Call this on logout to reset both clients (clears cached tokens from headers).
  static void reset() {
    _adminDio = null;
    _hospitalDio = null;
    _passwordDio = null;
  }
}
