import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/network_exceptions.dart';
import '../repository/patients_repository.dart';
import 'patients_state.dart';

class PatientsCubit extends Cubit<PatientsState> {
  PatientsCubit() : super(const PatientsInitial());

  final _repo = const PatientsRepository();

  Future<void> fetchPatients() async {
    emit(const PatientsLoading());
    try {
      final response = await _repo.fetchPatients();
      emit(PatientsLoaded(response.data));
    } on NetworkException catch (e) {
      emit(PatientsFailure(e.message));
    } catch (_) {
      emit(const PatientsFailure('An unexpected error occurred'));
    }
  }

  Future<void> deletePatient(int id) async {
    final current = state;
    if (current is! PatientsLoaded) return;

    emit(PatientsActionLoading(current.patients));
    try {
      await _repo.deletePatient(id);
      final updated =
          current.patients.where((p) => p.id != id).toList();
      emit(PatientsActionSuccess(updated, 'Patient deleted successfully'));
    } on NetworkException catch (e) {
      emit(PatientsActionFailure(current.patients, e.message));
    } catch (_) {
      emit(PatientsActionFailure(
          current.patients, 'An unexpected error occurred'));
    }
  }
}

