import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/network_exceptions.dart';
import '../repository/patients_repository.dart';
import 'patient_details_state.dart';

class PatientDetailsCubit extends Cubit<PatientDetailsState> {
  PatientDetailsCubit() : super(const PatientDetailsInitial());

  final _repo = const PatientsRepository();

  Future<void> fetchPatient(int id) async {
    emit(const PatientDetailsLoading());
    try {
      final patient = await _repo.fetchPatientById(id);
      emit(PatientDetailsLoaded(patient));
    } on NetworkException catch (e) {
      emit(PatientDetailsFailure(e.message));
    } catch (_) {
      emit(const PatientDetailsFailure('An unexpected error occurred'));
    }
  }
}

