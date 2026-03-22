import 'package:equatable/equatable.dart';

import '../../login/models/admin_model.dart';

sealed class AdminFormState extends Equatable {
  const AdminFormState();
  @override
  List<Object?> get props => [];
}

final class AdminFormInitial extends AdminFormState {
  const AdminFormInitial();
}

final class AdminFormLoading extends AdminFormState {
  const AdminFormLoading();
}

final class AdminFormSuccess extends AdminFormState {
  const AdminFormSuccess({required this.admin, required this.message});

  final AdminModel admin;
  final String message;

  @override
  List<Object?> get props => [admin, message];
}

final class AdminFormFailure extends AdminFormState {
  const AdminFormFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
