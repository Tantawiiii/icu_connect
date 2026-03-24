import 'package:equatable/equatable.dart';

import '../data/forgot_password_response.dart';

sealed class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();

  @override
  List<Object?> get props => [];
}

final class ForgotPasswordInitial extends ForgotPasswordState {
  const ForgotPasswordInitial();
}

final class ForgotPasswordLoading extends ForgotPasswordState {
  const ForgotPasswordLoading();
}

final class ForgotPasswordSuccess extends ForgotPasswordState {
  const ForgotPasswordSuccess(this.response);

  final ForgotPasswordResponse response;

  @override
  List<Object?> get props => [response];
}

final class ForgotPasswordFailure extends ForgotPasswordState {
  const ForgotPasswordFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
