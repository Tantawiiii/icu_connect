import '../api_client.dart';
import '../api_constants.dart';
import '../token_storage.dart';
import 'base_api_service.dart';

// ── Request / Response models (lightweight inline) ────────────────────────

class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        user: json['user'] as Map<String, dynamic>,
      );
}

// ── Service ───────────────────────────────────────────────────────────────

/// Handles auth calls for both Admin and Hospital roles.
///
/// Usage:
/// ```dart
/// // Hospital login
/// final svc = AuthApiService(UserRole.hospital);
/// final res = await svc.login(LoginRequest(email: '...', password: '...'));
///
/// // Admin login
/// final adminSvc = AuthApiService(UserRole.admin);
/// final res = await adminSvc.login(LoginRequest(email: '...', password: '...'));
/// ```
class AuthApiService extends BaseApiService {
  const AuthApiService(super.role);

  /// Logs in the user, persists tokens, and returns [LoginResponse].
  Future<LoginResponse> login(LoginRequest request) async {
    final data = await post<Map<String, dynamic>>(
      ApiConstants.login,
      data: request.toJson(),
      cancelTag: 'auth_login',
    );

    final response = LoginResponse.fromJson(data);

    await TokenStorage.instance.saveAccessToken(response.accessToken);
    await TokenStorage.instance.saveRefreshToken(response.refreshToken);
    await TokenStorage.instance.saveUserRole(role.name);

    return response;
  }

  /// Logs out the user and clears all stored tokens.
  Future<void> logout() async {
    try {
      await post<void>(
        ApiConstants.logout,
        cancelTag: 'auth_logout',
      );
    } finally {
      await TokenStorage.instance.clearAll();
      ApiClient.reset();
    }
  }

  /// Sends a password-reset email.
  Future<void> forgotPassword(String email) async {
    await post<void>(
      ApiConstants.forgotPassword,
      data: {'email': email},
      cancelTag: 'auth_forgot_password',
    );
  }

  /// Resets the password using the token from the email.
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await post<void>(
      ApiConstants.resetPassword,
      data: {
        'token': token,
        'new_password': newPassword,
      },
      cancelTag: 'auth_reset_password',
    );
  }
}
