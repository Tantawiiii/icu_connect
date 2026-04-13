import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import '../../../superAdmin/patients/models/admission_request_model.dart';
import '../../../superAdmin/patients/models/patient_admission_models.dart';
import '../../../superAdmin/patients/models/patient_model.dart';
import '../../profile/repository/doctor_profile_repository.dart';
import '../repository/hospital_admissions_repository.dart';
import 'admission_form_state.dart';

AdmissionPatientModel _admissionPatientFromModel(PatientModel m) =>
    AdmissionPatientModel(
      id: m.id,
      name: m.name,
      nationalId: m.nationalId,
      age: m.age,
      gender: m.gender,
      phone: m.phone,
      bloodGroup: m.bloodGroup,
      notes: m.notes,
      createdAt: m.createdAt,
      updatedAt: m.updatedAt,
      deletedAt: m.deletedAt,
    );

class AdmissionFormCubit extends Cubit<AdmissionFormState> {
  AdmissionFormCubit() : super(const AdmissionFormInitial());

  final _repository = const HospitalAdmissionsRepository();
  AdmissionFormRefsReady? refs;

  Future<void> loadReferenceData() async {
    emit(const AdmissionFormLoadingRefs());
    try {
      final vitals = await _repository.listVitalsTitles();
      final labs = await _repository.listLabsTitles();
      final patients = await _repository.listPatients(perPage: 100);
      final profile = await const DoctorProfileRepository().fetchProfile();
      refs = AdmissionFormRefsReady(
        vitalsTitles: vitals,
        labsTitles: labs,
        patients: patients,
        currentDoctorId: profile.id,
      );
      emit(refs!);
    } on NetworkException catch (e) {
      emit(AdmissionFormFailure(e.message));
    }
  }

  /// Reloads patients for the dropdown (e.g. after creating a patient).
  /// If [ensurePatientId] is set and missing from the first page, loads that patient via GET.
  Future<void> refreshPatients({int? ensurePatientId}) async {
    final r = refs;
    if (r == null) {
      await loadReferenceData();
      return;
    }
    try {
      var patients = await _repository.listPatients(perPage: 100);
      if (ensurePatientId != null) {
        final exists = patients.any((p) => p.id == ensurePatientId);
        if (!exists) {
          final pm = await _repository.getPatient(ensurePatientId);
          patients = [_admissionPatientFromModel(pm), ...patients];
        }
      }
      refs = AdmissionFormRefsReady(
        vitalsTitles: r.vitalsTitles,
        labsTitles: r.labsTitles,
        patients: patients,
        currentDoctorId: r.currentDoctorId,
      );
      emit(refs!);
    } on NetworkException {
      rethrow;
    }
  }

  Future<void> createAdmission(AdmissionCreateRequest req) async {
    emit(const AdmissionFormSubmitting());
    try {
      final fd = await req.toFormData();
      await _repository.createAdmission(fd);
      emit(const AdmissionFormSuccess('Admission created successfully.'));
    } on NetworkException catch (e) {
      emit(AdmissionFormFailure(e.message));
    }
  }

  Future<void> updateAdmission(int id, AdmissionUpdateRequest req) async {
    emit(const AdmissionFormSubmitting());
    try {
      final fd = await req.toFormData();
      await _repository.updateAdmission(id, fd);
      emit(const AdmissionFormSuccess('Admission updated successfully.'));
    } on NetworkException catch (e) {
      emit(AdmissionFormFailure(e.message));
    }
  }

}
