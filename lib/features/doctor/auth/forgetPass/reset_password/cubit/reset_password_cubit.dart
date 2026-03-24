import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:icu_connect/core/network/network_exceptions.dart';

import '../repository/reset_password_repository.dart';
import 'reset_password_state.dart';

class DoctorResetPasswordCubit extends Cubit<DoctorResetPasswordState> {
  DoctorResetPasswordCubit(this._repository)
    : super(const DoctorResetPasswordInitial());

  final ResetPasswordRepository _repository;

  Future<void> reset({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (state is DoctorResetPasswordLoading) return;
    emit(const DoctorResetPasswordLoading());
    try {
      final response = await _repository.reset(
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      emit(DoctorResetPasswordSuccess(response));
    } on NetworkException catch (e) {
      emit(DoctorResetPasswordFailure(e.message));
    } catch (_) {
      emit(const DoctorResetPasswordFailure('An unexpected error occurred.'));
    }
  }
}
