import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/network/network_exceptions.dart';
import '../repository/doctor_hospitals_repository.dart';
import 'doctor_hospitals_state.dart';

class DoctorHospitalsCubit extends Cubit<DoctorHospitalsState> {
  DoctorHospitalsCubit(this._repository) : super(const DoctorHospitalsInitial());

  final DoctorHospitalsRepository _repository;

  Future<void> load() async {
    emit(const DoctorHospitalsLoading());
    try {
      final list = await _repository.fetchHospitals();
      emit(DoctorHospitalsLoaded(list));
    } on NetworkException catch (e) {
      emit(DoctorHospitalsFailure(e.message));
    } catch (e) {
      emit(DoctorHospitalsFailure(e.toString()));
    }
  }

  Future<void> refresh() => load();
}
