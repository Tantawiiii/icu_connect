import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_texts.dart';
import '../../../../../core/network/network_exceptions.dart';
import '../repository/doctor_signup_repository.dart';
import 'doctor_signup_state.dart';

class DoctorSignupCubit extends Cubit<DoctorSignupState> {
  DoctorSignupCubit(this._repository) : super(const DoctorSignupInitial());

  final DoctorSignupRepository _repository;

  Future<void> loadHospitals() async {
    if (state is DoctorSignupHospitalsLoading) return;

    emit(const DoctorSignupHospitalsLoading());
    try {
      final hospitals = await _repository.fetchHospitals();
      emit(
        DoctorSignupReady(
          hospitals: hospitals,
          selectedHospitalId: hospitals.isNotEmpty ? hospitals.first.id : null,
        ),
      );
    } on NetworkException catch (e) {
      emit(DoctorSignupHospitalsFailure(e.message));
    } catch (_) {
      emit(const DoctorSignupHospitalsFailure('Could not load hospitals.'));
    }
  }

  void selectHospital(int? id) {
    final s = state;
    if (s is DoctorSignupReady) {
      emit(DoctorSignupReady(hospitals: s.hospitals, selectedHospitalId: id));
    }
    if (s is DoctorSignupSubmitting) {
      emit(
        DoctorSignupSubmitting(hospitals: s.hospitals, selectedHospitalId: id),
      );
    }
  }

  Future<void> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    final ready = switch (state) {
      DoctorSignupReady r => r,
      DoctorSignupSubmitting(:final hospitals, :final selectedHospitalId) =>
        DoctorSignupReady(
          hospitals: hospitals,
          selectedHospitalId: selectedHospitalId,
        ),
      _ => null,
    };
    if (ready == null) return;

    final hospitalId = ready.selectedHospitalId;
    if (hospitalId == null) {
      emit(
        DoctorSignupSignupFailure(
          recover: ready,
          message: AppTexts.hospitalRequired,
        ),
      );
      return;
    }

    emit(
      DoctorSignupSubmitting(
        hospitals: ready.hospitals,
        selectedHospitalId: ready.selectedHospitalId,
      ),
    );

    try {
      final response = await _repository.signup(
        name: name,
        email: email,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
        hospitalId: hospitalId,
      );
      emit(DoctorSignupSuccess(response));
    } on NetworkException catch (e) {
      emit(
        DoctorSignupSignupFailure(
          recover: DoctorSignupReady(
            hospitals: ready.hospitals,
            selectedHospitalId: ready.selectedHospitalId,
          ),
          message: e.message,
        ),
      );
    } catch (_) {
      emit(
        DoctorSignupSignupFailure(
          recover: DoctorSignupReady(
            hospitals: ready.hospitals,
            selectedHospitalId: ready.selectedHospitalId,
          ),
          message: 'An unexpected error occurred.',
        ),
      );
    }
  }

  void clearSignupFailure() {
    final s = state;
    if (s is DoctorSignupSignupFailure) {
      emit(s.recover);
    }
  }
}
