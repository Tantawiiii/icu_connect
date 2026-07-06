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
  static const String hospitalOtherOptional = 'Other (optional)';
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
  static const String dashboardOverview = 'Overview';
  static const String dashboardTotalHospitals = 'Hospitals';
  static const String dashboardTotalPatients = 'Patients';
  static const String dashboardTotalDoctors = 'Doctors';
  static const String dashboardTotalAdmissions = 'All admissions';
  static const String dashboardActiveAdmissions = 'Active admissions';
  static const String dashboardRecentAdmissions = 'Recent admissions';
  static const String dashboardNoRecentAdmissions = 'No recent admissions.';
  static const String adminInfo = 'Admin Info';
  static const String logoutConfirmMessage = 'Are you sure you want to logout?';

  // Super Admin profile
  static const String myProfile = 'My Profile';
  static const String name = 'Name';
  static const String firstName = 'First name';
  static const String lastName = 'Last name';
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

  // Super admin - user form
  static const String basicInformation = 'Basic Information';
  static const String accountSettings = 'Account Settings';
  static const String enableOrDisableThisAccount =
      'Enable or disable this account';
  static const String changePassword = 'Change Password';
  static const String passwordMustBeAtLeast8Characters =
      'Password must be at least 8 characters';
  static const String allHospitalsAlreadyAssigned =
      'All available hospitals are already assigned';
  static const String add = 'Add';
  static const String remove = 'Remove';

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
  static const String requestNewHospital = 'Request new hospital';
  static const String myHospitalRequests = 'My hospital requests';
  static const String hospitalRequests = 'Hospital requests';
  static const String hospitalRequestsTab = 'Requests';
  static const String hospitalRequestsAll = 'All';
  static const String hospitalRequestsPending = 'Pending';
  static const String hospitalRequestsAccepted = 'Accepted';
  static const String hospitalRequestsRejected = 'Rejected';
  static const String hospitalRequestSubmitted =
      'Hospital request submitted successfully';
  static const String hospitalRequestSubmitFailed =
      'Could not submit hospital request.';
  static const String noHospitalRequests = 'No hospital requests found.';
  static const String acceptHospitalRequest = 'Accept';
  static const String rejectHospitalRequest = 'Reject';
  static const String acceptHospitalRequestConfirmation =
      'Accept this hospital request?';
  static const String rejectHospitalRequestConfirmation =
      'Reject this hospital request?';
  static const String hospitalRequestAccepted =
      'Hospital request accepted successfully';
  static const String hospitalRequestRejected =
      'Hospital request rejected successfully';
  static const String hospitalRequestStatusAccepted = 'Accepted';
  static const String hospitalRequestStatusPending = 'Pending';
  static const String hospitalRequestStatusRejected = 'Rejected';
  static const String addHospitalGroup = 'Add Group';
  static const String removeHospitalGroup = 'Remove Group';
  static const String hospitalGroupName = 'Group Name';
  static const String hospitalInformation = 'Hospital Information';
  static const String hospitalGroups = 'Hospital Groups';
  static const String availableBedsCannotExceedTotal =
      'Available beds cannot exceed total beds';

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
  static const String editEntry = 'Edit entry';
  static const String saveChanges = 'Save changes';
  static const String entryUpdated = 'Entry updated';
  static const String deleteEntry = 'Delete entry';
  static const String admissionDeleted = 'Admission deleted successfully';
  static const String activityHistorySection = 'Activity history';
  static const String activityFilterAll = 'All';
  static const String noActivityYet = 'No activity recorded yet.';
  static const String activityLoadFailed = 'Could not load activity.';
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
  static const String patientLabel = 'Patient';
  static const String selectPatient = 'Select patient';
  static const String optional = 'optional';
  static const String admissionOptionalRecords = 'Additional records (optional)';
  static const String admissionOptionalRecordsHint =
      'History and complaint, vitals, labs, medications, and more';
  static const String admissionNotesSection = 'Admission notes';
  static const String clinicalNotesSection = 'History and complaint';
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
  static const String searchLabsTitlesHint =
      'Search by title, unit, or normal range';
  static const String labsTitlesSearchEmpty =
      'No lab titles match your search.';
  static const String addLabTitle = 'Add Lab Title';
  static const String editLabTitle = 'Edit Lab Title';
  static const String deleteLabTitle = 'Delete Lab Title';
  static const String deleteLabTitleConfirmation =
      'Are you sure you want to delete this lab title?';
  static const String labTitleCreated = 'Lab title created successfully';
  static const String labTitleUpdated = 'Lab title updated successfully';
  static const String labTitleDeleted = 'Lab title deleted successfully';
  static const String unit = 'Unit';
  static const String normalRangeMin = 'Min Val';
  static const String normalRangeMax = 'Max Val';
  static const String normalRangeMaxMustExceedMin =
      'Maximum must be greater than minimum';
  static const String Min = 'Min Val';
  static const String Max = 'Max Val';

  // Vitals titles CRUD
  static const String vitalsLabel = 'Vitals';
  static const String vitalsTitlesLabel = 'Vitals Titles';
  static const String searchVitalsTitlesHint =
      'Search by title, unit, or normal range';
  static const String vitalsTitlesSearchEmpty =
      'No vital titles match your search.';
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
  static const String searchHospitalsHint =
      'Search by hospital name or location';
  static const String hospitalsSearchEmpty = 'No hospitals match your search.';
  static const String searchBedsHint = 'Search by bed number or patient name';
  static const String bedsSearchEmpty = 'No beds match your search.';
  static const String addPatient = '+ ADD PATIENT';
  static const String yourHospitals = 'Hospitals';
  static const String myHospitalsSection = 'My hospitals';
  static const String pendingHospitalRequestsSection = 'Pending requests';
  static const String availableHospitalsSection = 'Available hospitals';
  static const String hospitalBedsSummary = 'Beds';
  static const String hospitalStatusPending = 'Pending approval';
  static const String hospitalStatusRejected = 'Rejected';
  static const String hospitalStatusNotMember = 'Not assigned';
  static const String hospitalStatusRequestAccess = 'Request access';
  static const String hospitalAccessGranted = 'Active';
  static const String hospitalLockedHint =
      'You need an approved assignment to open this hospital.';
  static const String hospitalJoinRequestTitle = 'Request to join this hospital?';
  static const String hospitalJoinRequestMessage =
      'This will update your profile and send a join request for this hospital.';
  static const String sendJoinRequest = 'Send request';
  static const String hospitalJoinRequestSent = 'Join request sent';
  static const String hospitalJoinRequestFailed = 'Could not send request.';
  static const String joinRequestSending = 'Sending request…';
  static const String viewHospitalDoctors = 'Doctors';
  static const String doctorsInHospital = 'Doctors in hospital';
  static const String acceptDoctor = 'Accept';
  static const String activateDoctor = 'Activate';
  static const String removeDoctorFromHospital = 'Remove from hospital';
  static const String removeDoctorConfirmation =
      'Remove this doctor from the hospital?';
  static const String doctorRemovedFromHospital =
      'Doctor removed from hospital';
  static const String addDoctor = 'Add doctor';
  static const String createDoctor = 'Create doctor';
  static const String doctorName = 'Doctor name';
  static const String doctorCreatedSuccessfully = 'Doctor created successfully';
  static const String doctorAddedSuccessfully = 'Doctor added successfully';
  static const String addDoctorPendingPoolSection =
      'Pending doctors (link to hospital)';
  static const String addDoctorRequestsSection = 'Inactive pending requests';
  static const String hospitalGroupsSummary = 'Groups';
  static const String selectHospitalGroup = 'Select group';
  static const String totalBedsShort = 'Total Beds';
  static const String availableBedsShort = 'Available';
  static const String dischargedPatients = 'Discharged Patients';
  static const String dischargedFilterAll = 'All';
  static const String dischargedPeriodLastMonth = 'Last Month';
  static const String dischargedPeriodLast3Months = 'Last 3 Months';
  static const String dischargedPeriodLastYear = 'Last Year';
  static const String dischargedPeriodAllTime = 'All time';
  static const String dischargedStatsImproved = 'Improved';
  static const String dischargedStatsDie = 'Die';
  static const String dischargedStatsDama = 'DAMA';
  static const String dischargedEmpty = 'No discharged patients in this period.';
  static const String dischargedSearchHint =
      'Search by name, bed, ID, or outcome';
  static const String dischargedSearchEmpty =
      'No discharged patients match your search.';
  static const String noBedsInGroup = 'No beds in this group';

  // Bed swap
  static const String swapBeds = 'Swap beds';
  static const String swapBedsSelectFirst =
      'Tap the first occupied bed to swap';
  static const String swapBedsSelectSecond =
      'Tap the second occupied bed — switch group if needed';
  static const String swapBedsSwitchGroupHint =
      'Pick another group to choose a bed from a different ward';
  static const String swapBedsCrossGroupNote =
      'Swapping beds across different groups';
  static const String swapBedsEmptyBedHint =
      'Only occupied beds can be swapped';
  static const String swapBedsConfirmTitle = 'Confirm bed swap';
  static const String swapBedsConfirmMessage =
      'Patients will exchange beds. Their records stay linked to the same admission.';
  static const String swapBedsSuccess = 'Beds swapped successfully';
  static const String swapBedsFailed = 'Could not swap beds';
  static const String confirmSwap = 'Confirm swap';
  static const String bedLabel = 'Bed';

  // Admission PDF export
  static const String exportAdmissionPdf = 'Export PDF';
  static const String admissionPdfExportFailed = 'Could not export admission PDF';
  static const String admissionPdfGenerating = 'Generating PDF…';

  // Admission form validation
  static const String admissionLeaveNotBeforeComes =
      'Leave date and time must be on or after admission.';
  static const String admissionDeathNotBeforeComes =
      'Date of death must be on or after admission.';
  static const String admissionSetComesFirst = 'Set admission date first.';

  // Drawer
  static const String profile = 'Profile';
  static const String profileScreenTitle = 'My profile';
  static const String profileUpdateSuccess = 'Profile updated successfully';
  static const String profileJoinHospitalHint =
      'Request to join another hospital';
  static const String passwordOptionalHint =
      'New password (leave blank to keep current)';
  static const String profileMinOneHospital =
      'Add at least one hospital to your profile.';
  static const String profileAccountSection = 'Account';
  static const String profileHospitalsSection = 'Hospitals & requests';
  static const String profileAllHospitalsInList =
      'All available hospitals are already in your list.';
  static const String statistics = 'Statistics';
  static const String aboutUs = 'About Us';
  static const String helpAndSupport = 'Help & Support';
  static const String privacyPolicy = 'Privacy Policy';
  static const String termsOfUse = 'Terms of Use';
  static const String reportProblem = 'Report a Problem';
  static const String setting = 'Settings';
  static const String trash = 'Trash';
  static const String logOut = 'Log Out';
  static const String deleteAccount = 'Delete account';
  static const String deleteAccountConfirmTitle = 'Delete account?';
  static const String deleteAccountConfirmMessage = 'This will permanently delete your account and data. This cannot be undone.';

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
  static const String cultures = 'Clutures';
  static const String medication = 'Medication';
  static const String plans = 'Plans';
  static const String vitalSigns = 'Vital Signs';
  static const String labs = 'Labs';
}
