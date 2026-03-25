import '../../../superAdmin/patients/models/patient_admission_models.dart';

class HospitalPatientsPageResult {
  const HospitalPatientsPageResult({
    required this.patients,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<AdmissionPatientModel> patients;
  final int currentPage;
  final int lastPage;
  final int total;
}
