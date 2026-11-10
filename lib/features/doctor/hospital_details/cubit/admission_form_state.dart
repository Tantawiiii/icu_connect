import '../../../superAdmin/patients/models/patient_admission_models.dart';

abstract class DoctorAdmissionFormState {
  const DoctorAdmissionFormState();
}

class DoctorAdmissionFormInitial extends DoctorAdmissionFormState {
  const DoctorAdmissionFormInitial();
}

class DoctorAdmissionFormLoadingRefs extends DoctorAdmissionFormState {
  const DoctorAdmissionFormLoadingRefs();
}

class DoctorAdmissionFormRefsReady extends DoctorAdmissionFormState {
  const DoctorAdmissionFormRefsReady({
    required this.vitalsTitles,
    required this.labsTitles,
    required this.patients,
    required this.currentDoctorId,
  });

  final List<MeasurementTitleModel> vitalsTitles;
  final List<MeasurementTitleModel> labsTitles;
  final List<AdmissionPatientModel> patients;

  /// Logged-in user id from `GET /auth/profile` (sent as `doctor_id` on create).
  final int currentDoctorId;
}

class DoctorAdmissionFormSubmitting extends DoctorAdmissionFormState {
  const DoctorAdmissionFormSubmitting();
}

class DoctorAdmissionFormSuccess extends DoctorAdmissionFormState {
  const DoctorAdmissionFormSuccess(this.message);
  final String message;
}

class DoctorAdmissionFormFailure extends DoctorAdmissionFormState {
  const DoctorAdmissionFormFailure(this.message);
  final String message;
}
