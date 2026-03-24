import 'package:equatable/equatable.dart';

import '../models/doctor_login_response.dart';

sealed class DoctorLoginState extends Equatable {
  const DoctorLoginState();

  @override
  List<Object?> get props => [];
}

final class DoctorLoginInitial extends DoctorLoginState {
  const DoctorLoginInitial();
}

final class DoctorLoginLoading extends DoctorLoginState {
  const DoctorLoginLoading();
}

final class DoctorLoginSuccess extends DoctorLoginState {
  const DoctorLoginSuccess(this.response);

  final DoctorLoginResponse response;

  @override
  List<Object?> get props => [response];
}

final class DoctorLoginFailure extends DoctorLoginState {
  const DoctorLoginFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
