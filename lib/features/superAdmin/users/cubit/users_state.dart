import 'package:equatable/equatable.dart';

import '../models/user_model.dart';

abstract class UsersState extends Equatable {
  const UsersState();

  @override
  List<Object?> get props => [];
}

class UsersInitial extends UsersState {
  const UsersInitial();
}

class UsersLoading extends UsersState {
  const UsersLoading();
}

class UsersLoaded extends UsersState {
  const UsersLoaded(this.users);
  final List<UserModel> users;

  @override
  List<Object?> get props => [users];
}

class UsersFailure extends UsersState {
  const UsersFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class UsersActionLoading extends UsersLoaded {
  const UsersActionLoading(super.users);
}

class UsersActionSuccess extends UsersLoaded {
  const UsersActionSuccess(super.users, this.message);
  final String message;

  @override
  List<Object?> get props => [users, message];
}

class UsersActionFailure extends UsersLoaded {
  const UsersActionFailure(super.users, this.message);
  final String message;

  @override
  List<Object?> get props => [users, message];
}
