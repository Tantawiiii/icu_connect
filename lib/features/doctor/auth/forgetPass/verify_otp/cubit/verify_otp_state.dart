import 'package:equatable/equatable.dart';

import '../data/verify_otp_response.dart';

sealed class VerifyOtpState extends Equatable {
  const VerifyOtpState();

  @override
  List<Object?> get props => [];
}

final class VerifyOtpInitial extends VerifyOtpState {
  const VerifyOtpInitial();
}

final class VerifyOtpLoading extends VerifyOtpState {
  const VerifyOtpLoading();
}

final class VerifyOtpSuccess extends VerifyOtpState {
  const VerifyOtpSuccess(this.response);

  final VerifyOtpResponse response;

  @override
  List<Object?> get props => [response];
}

final class VerifyOtpFailure extends VerifyOtpState {
  const VerifyOtpFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
