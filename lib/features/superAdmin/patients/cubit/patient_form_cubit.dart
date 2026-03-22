import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/network_exceptions.dart';
import '../models/patient_request_model.dart';
import '../repository/patients_repository.dart';
import 'patient_form_state.dart';

class PatientFormCubit extends Cubit<PatientFormState> {
  PatientFormCubit() : super(const PatientFormInitial());

  final _repo = const PatientsRepository();

  Future<void> createPatient(PatientRequest request) async {
    emit(const PatientFormLoading());
    try {
      await _repo.createPatient(request);
      emit(const PatientFormSuccess('Patient created successfully'));
    } on NetworkException catch (e) {
      emit(PatientFormFailure(e.message));
    } catch (_) {
      emit(const PatientFormFailure('An unexpected error occurred'));
    }
  }

  Future<void> updatePatient(int id, PatientRequest request) async {
    emit(const PatientFormLoading());
    try {
      await _repo.updatePatient(id, request);
      emit(const PatientFormSuccess('Patient updated successfully'));
    } on NetworkException catch (e) {
      emit(PatientFormFailure(e.message));
    } catch (_) {
      emit(const PatientFormFailure('An unexpected error occurred'));
    }
  }
}

