import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/network/network_exceptions.dart';
import '../repository/hospital_doctors_repository.dart';
import 'hospital_doctors_state.dart';

class HospitalDoctorsCubit extends Cubit<HospitalDoctorsState> {
  HospitalDoctorsCubit(this._repository) : super(const HospitalDoctorsInitial());

  final HospitalDoctorsRepository _repository;

  Future<void> load(int hospitalId) async {
    emit(const HospitalDoctorsLoading());
    try {
      final doctors = await _repository.fetchDoctors(hospitalId);
      emit(HospitalDoctorsLoaded(doctors: doctors));
    } on NetworkException catch (e) {
      emit(HospitalDoctorsFailure(e.message));
    } catch (_) {
      emit(const HospitalDoctorsFailure('Could not load doctors.'));
    }
  }

  Future<void> refresh(int hospitalId) => load(hospitalId);

  Future<void> acceptDoctor({
    required int hospitalId,
    required int doctorId,
  }) async {
    final s = state;
    if (s is! HospitalDoctorsLoaded) return;
    final accepting = {...s.acceptingIds, doctorId};
    emit(s.copyWith(acceptingIds: accepting));
    try {
      await _repository.acceptDoctor(hospitalId: hospitalId, doctorId: doctorId);
      await refresh(hospitalId);
    } on NetworkException catch (e) {
      emit(s.copyWith(acceptingIds: accepting..remove(doctorId)));
      emit(HospitalDoctorsFailure(e.message));
      emit(s.copyWith(acceptingIds: accepting..remove(doctorId)));
    } catch (_) {
      emit(s.copyWith(acceptingIds: accepting..remove(doctorId)));
      emit(const HospitalDoctorsFailure('Could not accept doctor.'));
      emit(s.copyWith(acceptingIds: accepting..remove(doctorId)));
    }
  }

  Future<void> activateDoctor({
    required int hospitalId,
    required int doctorId,
  }) async {
    final s = state;
    if (s is! HospitalDoctorsLoaded) return;
    final activating = {...s.activatingIds, doctorId};
    emit(s.copyWith(activatingIds: activating));
    try {
      await _repository.activateDoctor(doctorId);
      await refresh(hospitalId);
    } on NetworkException catch (e) {
      emit(s.copyWith(activatingIds: activating..remove(doctorId)));
      emit(HospitalDoctorsFailure(e.message));
      emit(s.copyWith(activatingIds: activating..remove(doctorId)));
    } catch (_) {
      emit(s.copyWith(activatingIds: activating..remove(doctorId)));
      emit(const HospitalDoctorsFailure('Could not activate doctor.'));
      emit(s.copyWith(activatingIds: activating..remove(doctorId)));
    }
  }

  Future<void> createDoctor({
    required int hospitalId,
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    final s = state;
    if (s is! HospitalDoctorsLoaded) return;
    emit(s.copyWith(creating: true));
    try {
      await _repository.createDoctor(
        hospitalId: hospitalId,
        name: name,
        email: email,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      await refresh(hospitalId);
    } on NetworkException catch (e) {
      emit(s.copyWith(creating: false));
      emit(HospitalDoctorsFailure(e.message));
      emit(s.copyWith(creating: false));
    } catch (_) {
      emit(s.copyWith(creating: false));
      emit(const HospitalDoctorsFailure('Could not create doctor.'));
      emit(s.copyWith(creating: false));
    }
  }
}

