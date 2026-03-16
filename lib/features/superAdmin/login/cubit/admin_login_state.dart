import 'package:equatable/equatable.dart';

import '../models/admin_login_response.dart';

sealed class AdminLoginState extends Equatable {
  const AdminLoginState();

  @override
  List<Object?> get props => [];
}

final class AdminLoginInitial extends AdminLoginState {
  const AdminLoginInitial();
}

final class AdminLoginLoading extends AdminLoginState {
  const AdminLoginLoading();
}

final class AdminLoginSuccess extends AdminLoginState {
  const AdminLoginSuccess(this.response);

  final AdminLoginResponse response;

  @override
  List<Object?> get props => [response];
}

final class AdminLoginFailure extends AdminLoginState {
  const AdminLoginFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
