import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:icu_connect/core/network/network_exceptions.dart';

import '../repository/verify_otp_repository.dart';
import 'verify_otp_state.dart';

class VerifyOtpCubit extends Cubit<VerifyOtpState> {
  VerifyOtpCubit(this._repository) : super(const VerifyOtpInitial());

  final VerifyOtpRepository _repository;

  Future<void> verify({required String email, required String otpCode}) async {
    if (state is VerifyOtpLoading) return;
    emit(const VerifyOtpLoading());
    try {
      final response = await _repository.verify(email: email, otpCode: otpCode);
      emit(VerifyOtpSuccess(response));
    } on NetworkException catch (e) {
      emit(VerifyOtpFailure(e.message));
    } catch (_) {
      emit(const VerifyOtpFailure('An unexpected error occurred.'));
    }
  }
}
