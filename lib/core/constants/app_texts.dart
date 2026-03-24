class AppTexts {
  // App Name
  static const String appName = 'ICU Connect';

  // Auth – fields & buttons
  static const String login = 'LOGIN';
  static const String userNameHint = 'USER NAME';
  static const String passwordHint = 'PASSWORD';
  static const String emailLabel = 'Email';
  static const String passwordLabel = 'Password';
  static const String cancel = 'Cancel';

  // Onboarding
  static const String skip = 'Skip';
  static const String getStarted = 'Get Started';

  // Auth – validation messages
  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'Enter a valid email';
  static const String passwordRequired = 'Password is required';
  static const String nameRequired = 'Name is required';
  static const String phoneRequired = 'Phone is required';
  static const String createNewAccount = 'Create new account';
  static const String registerTitle = 'Create account';
  static const String confirmPasswordLabel = 'Confirm password';
  static const String confirmPasswordRequired = 'Please confirm your password';
  static const String passwordsDoNotMatch = 'Passwords do not match';
  static const String hospitalLabel = 'Hospital';
  static const String selectHospital = 'Select a hospital';
  static const String hospitalRequired = 'Please select a hospital';
  static const String noHospitalsAvailable = 'No hospitals available.';
  static const String register = 'REGISTER';
  static const String registrationPendingTitle = 'Registration submitted';
  static const String registrationPendingExplanation =
      'Your account is pending approval by the hospital administrator. '
      'When your request is approved, we will notify you by email. '
      'Please check your inbox (and spam folder) for updates.';
  static const String backToLogin = 'Back to login';

  // Password reset (doctor)
  static const String forgotPassword = 'Forgot password?';
  static const String forgotPasswordTitle = 'Forgot password';
  static const String sendOtp = 'Send code';
  static const String verifyOtpTitle = 'Verify code';
  static const String otpLabel = 'Verification code';
  static const String otpHint = 'Enter 6-digit code';
  static const String otpRequired = 'Please enter the verification code';
  static const String otpInvalidLength = 'Code must be 6 digits';
  static const String verifyOtpButton = 'VERIFY';
  static const String resetPasswordTitle = 'New password';
  static const String resetPasswordButton = 'RESET PASSWORD';
  static const String passwordResetSuccess = 'Password reset successfully';

  // Super Admin dialog
  static const String superAdmin = 'Super Admin';
  static const String restrictedAccess = 'Restricted Access';

  // Super Admin home
  static const String welcomeBack = 'Welcome back,';
  static const String quickActions = 'Quick Actions';
  static const String adminInfo = 'Admin Info';
  static const String logoutConfirmMessage = 'Are you sure you want to logout?';

  // Super Admin profile
  static const String myProfile = 'My Profile';
  static const String name = 'Name';
  static const String phone = 'Phone';
  static const String lastLogin = 'Last Login';
  static const String status = 'Status';
  static const String active = 'Active';
  static const String inactive = 'Inactive';
  static const String notAvailable = 'N/A';

  // Quick action tiles
  static const String hospitalsLabel = 'Hospitals';
  static const String usersLabel = 'Users';
  static const String dashboardLabel = 'Dashboard';

  // Users CRUD
  static const String addUser = 'Add User';
  static const String editUser = 'Edit User';
  static const String deleteUser = 'Delete User';
  static const String restoreUser = 'Restore';
  static const String deleteUserConfirmation =
      'Are you sure you want to delete this user?';
  static const String restoreUserConfirmation =
      'Restore this deleted user?';
  static const String userCreated = 'User created successfully';
  static const String userUpdated = 'User updated successfully';
  static const String userDeleted = 'User deleted successfully';
  static const String userRestored = 'User restored successfully';
  static const String roleLabel = 'Role';
  static const String roleInHospital = 'Role in Hospital';
  static const String assignedHospitals = 'Assigned Hospitals';
  static const String addHospitalAssignment = 'Add Hospital';
  static const String noHospitalsAssigned = 'No hospitals assigned';

  // Hospitals CRUD
  static const String addHospital = 'Add Hospital';
  static const String editHospital = 'Edit Hospital';
  static const String deleteHospital = 'Delete Hospital';
  static const String restoreHospital = 'Restore';
  static const String deleteHospitalConfirmation =
      'Are you sure you want to delete this hospital?';
  static const String restoreHospitalConfirmation =
      'Restore this deleted hospital?';
  static const String location = 'Location';
  static const String totalBeds = 'Total Beds';
  static const String availableBeds = 'Available Beds';
  static const String occupiedBeds = 'Occupied Beds';
  static const String deleted = 'Deleted';
  static const String hospitalCreated = 'Hospital created successfully';
  static const String hospitalUpdated = 'Hospital updated successfully';
  static const String hospitalDeleted = 'Hospital deleted successfully';
  static const String hospitalRestored = 'Hospital restored successfully';

  // Patients CRUD (admin)
  static const String patientsLabel = 'Patients';
  static const String addPatientAdmin = 'Add Patient';
  static const String editPatientAdmin = 'Edit Patient';
  static const String deletePatientAdmin = 'Delete Patient';
  static const String deletePatientConfirmation =
      'Are you sure you want to delete this patient?';
  static const String patientCreated = 'Patient created successfully';
  static const String patientUpdated = 'Patient updated successfully';
  static const String patientDeleted = 'Patient deleted successfully';
  static const String addAdmission = 'Add admission';
  static const String editAdmission = 'Edit admission';
  static const String createAdmission = 'Create admission';
  static const String deleteAdmission = 'Delete admission';
  static const String deleteAdmissionConfirmation =
      'Delete this admission? Related records may be removed.';
  static const String admissionCreated = 'Admission created successfully';
  static const String admissionUpdated = 'Admission updated successfully';
  static const String admissionDeleted = 'Admission deleted successfully';
  static const String retry = 'Retry';

  /// Super admin patient details screen
  static const String patientDetailsTitle = 'Patient Details';
  static const String identifiersSection = 'Identifiers';
  static const String recordSection = 'Record';
  static const String createdLabel = 'Created';
  static const String updatedLabel = 'Updated';
  static const String admissionsSection = 'Admissions';
  static const String noAdmissionsYetPrefix = 'No admissions yet. Tap ';
  static const String noAdmissionsYetSuffix = ' to create one.';
  static const String patientDetailsHospital = 'Hospital';
  static const String patientDetailsDoctor = 'Doctor';
  static const String dischargedLabel = 'Discharged';
  static const String dateOfDeathLabel = 'Date of death';
  static const String admissionNotesSection = 'Admission notes';
  static const String clinicalNotesSection = 'Clinical notes';
  static const String treatmentPlansSection = 'Treatment plans';
  static const String defaultVitalMeasurementTitle = 'Vital';
  static const String defaultLabMeasurementTitle = 'Lab';
  static const String normalRangePrefix = 'Normal:';
  static const String utcTimeZoneSuffix = ' UTC';

  static String admissionCardTitle(int id, String bedOrStatus) =>
      'Admission #$id · $bedOrStatus';

  static const String nationalId = 'National ID';
  static const String gender = 'Gender';
  static const String bloodGroup = 'Blood Group';
  static const String notes = 'Notes';
  static const String male = 'Male';
  static const String female = 'Female';
  static const String other = 'Other';

  // Labs titles CRUD
  static const String labsLabel = 'Labs';
  static const String labsTitlesLabel = 'Labs Titles';
  static const String addLabTitle = 'Add Lab Title';
  static const String editLabTitle = 'Edit Lab Title';
  static const String deleteLabTitle = 'Delete Lab Title';
  static const String deleteLabTitleConfirmation =
      'Are you sure you want to delete this lab title?';
  static const String labTitleCreated = 'Lab title created successfully';
  static const String labTitleUpdated = 'Lab title updated successfully';
  static const String labTitleDeleted = 'Lab title deleted successfully';
  static const String unit = 'Unit';
  static const String normalRangeMin = 'Normal Range Min';
  static const String normalRangeMax = 'Normal Range Max';

  // Vitals titles CRUD
  static const String vitalsLabel = 'Vitals';
  static const String vitalsTitlesLabel = 'Vitals Titles';
  static const String addVitalTitle = 'Add Vital Title';
  static const String editVitalTitle = 'Edit Vital Title';
  static const String deleteVitalTitle = 'Delete Vital Title';
  static const String deleteVitalTitleConfirmation =
      'Are you sure you want to delete this vital title?';
  static const String vitalTitleCreated = 'Vital title created successfully';
  static const String vitalTitleUpdated = 'Vital title updated successfully';
  static const String vitalTitleDeleted = 'Vital title deleted successfully';

  // Super admins CRUD
  static const String superAdmins = 'Super Admins';
  static const String addAdmin = 'Add Admin';
  static const String editAdmin = 'Edit Admin';
  static const String deleteAdmin = 'Delete Admin';
  static const String deleteAdminConfirmation =
      'Are you sure you want to delete this admin?';
  static const String confirmPassword = 'Confirm Password';
  static const String passwordLeaveBlank =
      'Password (leave blank to keep current)';
  static const String confirmPasswordLeaveBlank =
      'Confirm password (leave blank)';
  static const String adminCreated = 'Admin created successfully';
  static const String adminUpdated = 'Admin updated successfully';
  static const String adminDeleted = 'Admin deleted successfully';

  // Home
  static const String search = 'SEARCH';
  static const String addPatient = '+ ADD PATIENT';

  // Drawer
  static const String profile = 'Profile';
  static const String statistics = 'Statistics';
  static const String aboutUs = 'About Us';
  static const String reportProblem = 'Report Proplem'; // Keeping typo from wireframe? Correcting it to Problem
  static const String setting = 'Setting';
  static const String trash = 'Trash';
  static const String logOut = 'Log Out';

  // Patient Actions
  static const String save = 'SAVE';
  static const String edit = 'EDIT';
  static const String viewImages = 'View Images';
  static const String addImage = '+ Add Image';
  static const String addNote = '+ Add Note';
  
  // Patient Fields
  static const String bedNo = 'Bed No.';
  static const String admitted = 'Admitted';
  static const String age = 'Age';

  // Section Headers
  static const String historyAndComplaint = 'History and Complaint';
  static const String radiology = 'Radiology';
  static const String progressNote = 'Progress Note';
  static const String cultures = 'Clutures'; // Keeping typo? Correcting to Cultures
  static const String medication = 'Medication';
  static const String plans = 'Plans';
  static const String vitalSigns = 'Vital Signs';
  static const String labs = 'Labs';
}
