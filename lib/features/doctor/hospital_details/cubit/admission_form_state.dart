import '../../../superAdmin/patients/models/patient_admission_models.dart';

abstract class AdmissionFormState {
  const AdmissionFormState();
}

class AdmissionFormInitial extends AdmissionFormState {
  const AdmissionFormInitial();
}

class AdmissionFormLoadingRefs extends AdmissionFormState {
  const AdmissionFormLoadingRefs();
}

class AdmissionFormRefsReady extends AdmissionFormState {
  const AdmissionFormRefsReady({
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

class AdmissionFormSubmitting extends AdmissionFormState {
  const AdmissionFormSubmitting();
}

class AdmissionFormSuccess extends AdmissionFormState {
  const AdmissionFormSuccess(this.message);
  final String message;
}

class AdmissionFormFailure extends AdmissionFormState {
  const AdmissionFormFailure(this.message);
  final String message;
}
