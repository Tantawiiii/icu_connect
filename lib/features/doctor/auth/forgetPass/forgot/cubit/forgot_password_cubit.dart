import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:icu_connect/core/network/network_exceptions.dart';

import '../repository/forgot_password_repository.dart';
import 'forgot_password_state.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit(this._repository) : super(const ForgotPasswordInitial());

  final ForgotPasswordRepository _repository;

  Future<void> sendOtp({required String email}) async {
    if (state is ForgotPasswordLoading) return;
    emit(const ForgotPasswordLoading());
    try {
      final response = await _repository.requestOtp(email: email);
      emit(ForgotPasswordSuccess(response));
    } on NetworkException catch (e) {
      emit(ForgotPasswordFailure(e.message));
    } catch (_) {
      emit(const ForgotPasswordFailure('An unexpected error occurred.'));
    }
  }
}
