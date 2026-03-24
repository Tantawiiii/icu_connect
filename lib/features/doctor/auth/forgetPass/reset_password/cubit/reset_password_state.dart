import 'package:equatable/equatable.dart';

import '../data/reset_password_response.dart';

sealed class DoctorResetPasswordState extends Equatable {
  const DoctorResetPasswordState();

  @override
  List<Object?> get props => [];
}

final class DoctorResetPasswordInitial extends DoctorResetPasswordState {
  const DoctorResetPasswordInitial();
}

final class DoctorResetPasswordLoading extends DoctorResetPasswordState {
  const DoctorResetPasswordLoading();
}

final class DoctorResetPasswordSuccess extends DoctorResetPasswordState {
  const DoctorResetPasswordSuccess(this.response);

  final ResetPasswordFlowResponse response;

  @override
  List<Object?> get props => [response];
}

final class DoctorResetPasswordFailure extends DoctorResetPasswordState {
  const DoctorResetPasswordFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
