import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/network/network_exceptions.dart';
import '../../auth/signup/models/signup_hospital_item.dart';
import '../models/doctor_profile.dart';
import '../repository/doctor_profile_repository.dart';
import 'doctor_profile_state.dart';

class DoctorProfileCubit extends Cubit<DoctorProfileState> {
  DoctorProfileCubit(this._repository) : super(const DoctorProfileInitial());

  final DoctorProfileRepository _repository;

  Future<void> load() async {
    emit(const DoctorProfileLoading());
    try {
      final results = await Future.wait([
        _repository.fetchProfile(),
        _repository.fetchHospitalCatalog(),
      ]);
      final profile = results[0] as DoctorProfile;
      final catalog = results[1] as List<SignupHospitalItem>;
      emit(
        DoctorProfileReady(
          profile: profile,
          catalogHospitals: catalog,
          hospitalIds: profile.hospitals.map((h) => h.id).toList(),
        ),
      );
    } on NetworkException catch (e) {
      emit(DoctorProfileLoadFailure(e.message));
    } catch (_) {
      emit(const DoctorProfileLoadFailure('Could not load profile.'));
    }
  }

  void addHospitalId(int id) {
    final s = state;
    if (s is! DoctorProfileReady || s.isSaving) return;
    if (s.hospitalIds.contains(id)) return;
    emit(s.copyWith(hospitalIds: [...s.hospitalIds, id]));
  }

  void removeHospitalId(int id) {
    final s = state;
    if (s is! DoctorProfileReady || s.isSaving) return;
    emit(
      s.copyWith(
        hospitalIds: s.hospitalIds.where((i) => i != id).toList(),
      ),
    );
  }

  Future<void> save({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    final s = state;
    if (s is! DoctorProfileReady || s.isSaving) return;

    if (s.hospitalIds.isEmpty) return;

    final pwd = password.trim();
    if (pwd.isNotEmpty && pwd != passwordConfirmation.trim()) {
      emit(
        DoctorProfileSaveFailure(
          recover: s,
          message: 'Passwords do not match.',
        ),
      );
      return;
    }

    emit(s.copyWith(isSaving: true));
    try {
      final updated = await _repository.updateProfile(
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        hospitalIds: s.hospitalIds,
        password: pwd.isEmpty ? null : pwd,
        passwordConfirmation:
            pwd.isEmpty ? null : passwordConfirmation.trim(),
      );
      emit(
        DoctorProfileReady(
          profile: updated,
          catalogHospitals: s.catalogHospitals,
          hospitalIds: updated.hospitals.map((h) => h.id).toList(),
        ),
      );
    } on NetworkException catch (e) {
      emit(DoctorProfileSaveFailure(recover: s.copyWith(isSaving: false), message: e.message));
    } catch (_) {
      emit(
        DoctorProfileSaveFailure(
          recover: s.copyWith(isSaving: false),
          message: 'Could not update profile.',
        ),
      );
    }
  }

  void clearSaveFailure() {
    final st = state;
    if (st is DoctorProfileSaveFailure) {
      emit(st.recover);
    }
  }
}
