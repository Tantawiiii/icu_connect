/// Defines all base URLs and API endpoint paths for both roles.
///
/// Admin role  → https://api.icuconnect.org/api/v1/admin/...
/// Hospital role → https://api.icuconnect.org/api/v1/hospital/...
class ApiConstants {
  ApiConstants._();

  static const String _scheme = 'https';
  static const String _host = 'api.icuconnect.org';
  static const String _version = '/api/v1';

  static const String adminBaseUrl = '$_scheme://$_host$_version/admin';
  static const String hospitalBaseUrl = '$_scheme://$_host$_version/hospital';

  // ── Timeouts ─────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ── Shared auth endpoints (appended to whichever base URL is active) ─────
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // ── Hospital – patient endpoints ─────────────────────────────────────────
  static const String patients = '/patients';
  static String patientById(String id) => '/patients/$id';
  static const String patientVitalSigns = '/vital-signs';
  static String patientVitalSignsById(String patientId) =>
      '/patients/$patientId/vital-signs';
  static const String labs = '/labs';
  static String labsByPatientId(String patientId) => '/patients/$patientId/labs';

  // ── Admin – management endpoints ─────────────────────────────────────────
  static const String hospitals = '/hospitals';
  static String hospitalById(String id) => '/hospitals/$id';
  static const String users = '/users';
  static String userById(String id) => '/users/$id';
  static const String statistics = '/statistics';
  static const String dashboard = '/dashboard';

  // ── Profile ───────────────────────────────────────────────────────────────
  static const String profile = '/profile';
  static const String changePassword = '/profile/change-password';
}
