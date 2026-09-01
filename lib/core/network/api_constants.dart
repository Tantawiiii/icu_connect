
class ApiConstants {
  ApiConstants._();

  static const String _scheme = 'https';
  static const String _host = 'api.icuconnect.org';
  static const String _version = '/api/v1';

  static const String adminBaseUrl = '$_scheme://$_host$_version/admin';
  static const String hospitalBaseUrl = '$_scheme://$_host$_version/hospital';
  /// Shared (role-agnostic) API root — used by endpoints that accept any Sanctum user.
  static const String sharedBaseUrl = '$_scheme://$_host$_version';

  static const String passwordBaseUrl = '$_scheme://$_host$_version/password/';
  static const String imageBaseUrl = '$_scheme://$_host/storage/';

  static const String passwordForgot = 'forgot';
  static const String passwordVerifyOtp = 'verify-otp';
  static const String passwordReset = 'reset';

  // ── Timeouts ─────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
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
  static String admissionActivity(int id) => '/admissions/$id/activity';
  static String admissionNotes(int id) => '/admissions/$id/notes';
  static const String admissionsSwapBeds = '/admissions/swap-beds';

  // ── AI recommendations (admission-scoped, shared Sanctum routes) ────────────
  static String aiRecommend(String feature) =>
      '$sharedBaseUrl/ai/recommend/$feature';
  static const String aiRecommendMedication =
      '$sharedBaseUrl/ai/recommend/medication';
  static const String aiRecommendLabs = '$sharedBaseUrl/ai/recommend/labs';
  static const String aiRecommendVitals = '$sharedBaseUrl/ai/recommend/vitals';
  static const String aiRecommendTreatmentPlan =
      '$sharedBaseUrl/ai/recommend/treatment_plan';
  static const String aiRecommendImaging =
      '$sharedBaseUrl/ai/recommend/imaging';
  static const String aiRecommendDiagnosis =
      '$sharedBaseUrl/ai/recommend/diagnosis';
  static const String aiRecommendDischarge =
      '$sharedBaseUrl/ai/recommend/discharge';
  /// POST — AI-assisted drug lookup to prefill a new drug form.
  static const String aiDrugsLookup = '$sharedBaseUrl/ai/drugs/lookup';

  static const String patientVitalSigns = '/vital-signs';
  static String patientVitalSignsById(String patientId) =>
      '/patients/$patientId/vital-signs';
  static const String vitals = '/vitals';
  static const String labs = '/labs';
  static String labsByPatientId(String patientId) => '/patients/$patientId/labs';
  static String patientVitalsTitles(int patientId) =>
      '/patients/$patientId/vitals-titles';
  static String patientLabsTitles(int patientId) =>
      '/patients/$patientId/labs-titles';
  static String hospitalDoctors(int hospitalId) => '/hospitals/$hospitalId/doctors';
  static String hospitalDoctorsAdd(int hospitalId) =>
      '/hospitals/$hospitalId/doctors/add';
  static String hospitalAcceptDoctor(int hospitalId) =>
      '/hospitals/$hospitalId/doctors/accept';
  static String hospitalDoctorById(int hospitalId, int doctorId) =>
      '/hospitals/$hospitalId/doctors/$doctorId';
  static String doctorActivate(int doctorId) => '/doctors/$doctorId/activate';

  // ── Admin – management endpoints ─────────────────────────────────────────
  static const String hospitals = '/hospitals';
  static const String hospitalsRequest = '/hospitals/request';
  static const String hospitalsRequests = '/hospitals/requests';
  static String hospitalById(int id) => '/hospitals/$id';
  static String hospitalRestore(int id) => '/hospitals/$id/restore';
  static String hospitalAccept(int id) => '/hospitals/$id/accept';
  static String hospitalReject(int id) => '/hospitals/$id/reject';
  static const String users = '/users';
  static String userById(int id) => '/users/$id';
  static String userRestore(int id) => '/users/$id/restore';
  static const String labsTitles = '/labs-titles';
  static String labTitleById(int id) => '/labs-titles/$id';
  static const String vitalsTitles = '/vitals-titles';
  static String vitalTitleById(int id) => '/vitals-titles/$id';
  static const String drugs = '/drugs';
  static const String drugsFormulary = '/drugs';
  static String drugById(int id) => '/drugs/$id';
  static String drugArchive(int id) => '/drugs/$id/archive';
  static String drugRestore(int id) => '/drugs/$id/restore';
  /// GET — role-scoped dose-unit lookup list (mg, g, mcg, ...).
  static const String doseUnits = '/dose-units';
  static const String statistics = '/statistics';
  static const String dashboard = '/dashboard';
  static const String admins = '/admins';
  static String adminById(int id) => '/admins/$id';

  // ── Profile ───────────────────────────────────────────────────────────────
  static const String authProfile = '/auth/profile';
  static const String profile = '/profile';
  static const String changePassword = '/profile/change-password';
}
