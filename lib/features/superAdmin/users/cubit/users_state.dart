import 'package:equatable/equatable.dart';

import '../../admins/models/pagination_model.dart';
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
  const UsersLoaded(this.users, this.pagination);
  final List<UserModel> users;
  final PaginationModel pagination;

  @override
  List<Object?> get props => [users, pagination];
}

class UsersFailure extends UsersState {
  const UsersFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class UsersActionLoading extends UsersLoaded {
  const UsersActionLoading(super.users, super.pagination);
}

class UsersActionSuccess extends UsersLoaded {
  const UsersActionSuccess(super.users, super.pagination, this.message);
  final String message;

  @override
  List<Object?> get props => [users, pagination, message];
}

class UsersActionFailure extends UsersLoaded {
  const UsersActionFailure(super.users, super.pagination, this.message);
  final String message;

  @override
  List<Object?> get props => [users, pagination, message];
}
