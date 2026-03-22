import 'package:equatable/equatable.dart';

import '../../login/models/admin_model.dart';

sealed class AdminProfileState extends Equatable {
  const AdminProfileState();

  @override
  List<Object?> get props => [];
}

final class AdminProfileInitial extends AdminProfileState {
  const AdminProfileInitial();
}

final class AdminProfileLoading extends AdminProfileState {
  const AdminProfileLoading();
}

final class AdminProfileSuccess extends AdminProfileState {
  const AdminProfileSuccess(this.profile);

  final AdminModel profile;

  @override
  List<Object?> get props => [profile];
}

final class AdminProfileFailure extends AdminProfileState {
  const AdminProfileFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
