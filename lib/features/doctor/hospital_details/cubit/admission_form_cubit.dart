import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import '../../../superAdmin/patients/models/admission_request_model.dart';
import '../repository/hospital_admissions_repository.dart';
import 'admission_form_state.dart';

class AdmissionFormCubit extends Cubit<AdmissionFormState> {
  AdmissionFormCubit() : super(const AdmissionFormInitial());

  final _repository = const HospitalAdmissionsRepository();
  AdmissionFormRefsReady? refs;

  Future<void> loadReferenceData() async {
    emit(const AdmissionFormLoadingRefs());
    try {
      final vitals = await _repository.listVitalsTitles();
      final labs = await _repository.listLabsTitles();
      final patients = await _repository.listPatients(perPage: 10);
      refs = AdmissionFormRefsReady(
        vitalsTitles: vitals,
        labsTitles: labs,
        patients: patients,
      );
      emit(refs!);
    } on NetworkException catch (e) {
      emit(AdmissionFormFailure(e.message));
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
