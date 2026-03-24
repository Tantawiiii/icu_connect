import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/network/network_exceptions.dart';
import '../repository/doctor_auth_repository.dart';
import 'doctor_login_state.dart';

class DoctorLoginCubit extends Cubit<DoctorLoginState> {
  DoctorLoginCubit(this._repository) : super(const DoctorLoginInitial());

  final DoctorAuthRepository _repository;

  Future<void> login({required String email, required String password}) async {
    if (state is DoctorLoginLoading) return;

    emit(const DoctorLoginLoading());

    try {
      final response = await _repository.login(
        email: email,
        password: password,
      );
      emit(DoctorLoginSuccess(response));
    } on NetworkException catch (e) {
      emit(DoctorLoginFailure(e.message));
    } catch (_) {
      emit(const DoctorLoginFailure('An unexpected error occurred.'));
    }
  }
}
