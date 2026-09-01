import '../../hospitals/models/hospital_model.dart';
import '../../labs/models/lab_title_model.dart';
import '../../users/models/user_model.dart';
import '../../vitals/models/vital_title_model.dart';

abstract class AdminAdmissionFormState {
  const AdminAdmissionFormState();
}

class AdminAdmissionFormInitial extends AdminAdmissionFormState {
  const AdminAdmissionFormInitial();
}

class AdminAdmissionFormLoadingRefs extends AdminAdmissionFormState {
  const AdminAdmissionFormLoadingRefs();
}

class AdminAdmissionFormRefsReady extends AdminAdmissionFormState {
  const AdminAdmissionFormRefsReady({
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

class AdminAdmissionFormSubmitting extends AdminAdmissionFormState {
  const AdminAdmissionFormSubmitting();
}

class AdminAdmissionFormSuccess extends AdminAdmissionFormState {
  const AdminAdmissionFormSuccess(this.message);

  final String message;
}

/// Initial load of hospitals/users/titles failed.
class AdminAdmissionFormFailure extends AdminAdmissionFormState {
  const AdminAdmissionFormFailure(this.message);

  final String message;
}
