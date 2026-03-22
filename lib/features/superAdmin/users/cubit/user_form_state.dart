import 'package:equatable/equatable.dart';

abstract class UserFormState extends Equatable {
  const UserFormState();

  @override
  List<Object?> get props => [];
}

class UserFormInitial extends UserFormState {
  const UserFormInitial();
}

class UserFormLoading extends UserFormState {
  const UserFormLoading();
}

class UserFormSuccess extends UserFormState {
  const UserFormSuccess(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class UserFormFailure extends UserFormState {
  const UserFormFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
