import '../../hospitals/models/hospital_model.dart';
import '../../labs/models/lab_title_model.dart';
import '../../users/models/user_model.dart';
import '../../vitals/models/vital_title_model.dart';

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
    required this.hospitals,
    required this.users,
    required this.vitalTitles,
    required this.labTitles,
  });

  final List<HospitalModel> hospitals;
  final List<UserModel> users;
  final List<VitalTitleModel> vitalTitles;
  final List<LabTitleModel> labTitles;
}

class AdmissionFormSubmitting extends AdmissionFormState {
  const AdmissionFormSubmitting();
}

class AdmissionFormSuccess extends AdmissionFormState {
  const AdmissionFormSuccess(this.message);

  final String message;
}

/// Initial load of hospitals/users/titles failed.
class AdmissionFormFailure extends AdmissionFormState {
  const AdmissionFormFailure(this.message);

  final String message;
}
