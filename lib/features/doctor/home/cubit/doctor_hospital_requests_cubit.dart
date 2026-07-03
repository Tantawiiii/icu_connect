import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/network/network_exceptions.dart';
import '../repository/doctor_hospitals_repository.dart';
import 'doctor_hospital_requests_state.dart';

class DoctorHospitalRequestsCubit extends Cubit<DoctorHospitalRequestsState> {
  DoctorHospitalRequestsCubit(this._repository)
      : super(const DoctorHospitalRequestsInitial());

  final DoctorHospitalsRepository _repository;

  Future<void> load() async {
    emit(const DoctorHospitalRequestsLoading());
    try {
      final requests = await _repository.fetchMyHospitalRequests();
      emit(DoctorHospitalRequestsLoaded(requests));
    } on NetworkException catch (e) {
      emit(DoctorHospitalRequestsFailure(e.message));
    } catch (_) {
      emit(const DoctorHospitalRequestsFailure('An unexpected error occurred'));
    }
  }

  Future<void> refresh() => load();
}
