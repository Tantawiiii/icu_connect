
class ApiConstants {
  ApiConstants._();

  static const String _scheme = 'https';
  static const String _host = 'api.icuconnect.org';
  static const String _version = '/api/v1';

  static const String adminBaseUrl = '$_scheme://$_host$_version/admin';
  static const String hospitalBaseUrl = '$_scheme://$_host$_version/hospital';

  static const String passwordBaseUrl = '$_scheme://$_host$_version/password/';
  static const String imageBaseUrl = '$_scheme://$_host/storage/';

  static const String passwordForgot = 'forgot';
  static const String passwordVerifyOtp = 'verify-otp';
  static const String passwordReset = 'reset';

  // ── Timeouts ─────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ── Shared auth endpoints
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String signup = '/auth/signup';
  static const String authListHospitals = '/auth/list-hospitals';
  /// Authenticated doctor/hospital user — includes [user_status] per hospital.
  static const String authHospitals = '/auth/hospitals';

  // ── Hospital – patient endpoints ─────────────────────────────────────────
  static const String patients = '/patients';
  static String patientById(String id) => '/patients/$id';
  static const String admissions = '/admissions';
  static String admissionById(int id) => '/admissions/$id';
  static const String patientVitalSigns = '/vital-signs';
  static String patientVitalSignsById(String patientId) =>
      '/patients/$patientId/vital-signs';
  static const String labs = '/labs';
  static String labsByPatientId(String patientId) => '/patients/$patientId/labs';
  static String hospitalDoctors(int hospitalId) => '/hospitals/$hospitalId/doctors';
  static String hospitalAcceptDoctor(int hospitalId) =>
      '/hospitals/$hospitalId/doctors/accept';
  static String doctorActivate(int doctorId) => '/doctors/$doctorId/activate';

  // ── Admin – management endpoints ─────────────────────────────────────────
  static const String hospitals = '/hospitals';
  static String hospitalById(int id) => '/hospitals/$id';
  static String hospitalRestore(int id) => '/hospitals/$id/restore';
  static const String users = '/users';
  static String userById(int id) => '/users/$id';
  static String userRestore(int id) => '/users/$id/restore';
  static const String labsTitles = '/labs-titles';
  static String labTitleById(int id) => '/labs-titles/$id';
  static const String vitalsTitles = '/vitals-titles';
  static String vitalTitleById(int id) => '/vitals-titles/$id';
  static const String statistics = '/statistics';
  static const String dashboard = '/dashboard';
  static const String admins = '/admins';
  static String adminById(int id) => '/admins/$id';

  // ── Profile ───────────────────────────────────────────────────────────────
  static const String authProfile = '/auth/profile';
  static const String profile = '/profile';
  static const String changePassword = '/profile/change-password';
}
