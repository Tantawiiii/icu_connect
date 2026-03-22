import 'package:equatable/equatable.dart';

import '../../login/models/admin_model.dart';
import '../models/pagination_model.dart';

sealed class AdminsState extends Equatable {
  const AdminsState();
  @override
  List<Object?> get props => [];
}

final class AdminsInitial extends AdminsState {
  const AdminsInitial();
}

final class AdminsLoading extends AdminsState {
  const AdminsLoading();
}

final class AdminsLoaded extends AdminsState {
  const AdminsLoaded({required this.admins, required this.pagination});

  final List<AdminModel> admins;
  final PaginationModel pagination;

  @override
  List<Object?> get props => [admins, pagination];
}

final class AdminsFailure extends AdminsState {
  const AdminsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Emitted during delete / after a form save so the list can refresh.
final class AdminsActionLoading extends AdminsState {
  const AdminsActionLoading();
}

final class AdminsActionSuccess extends AdminsState {
  const AdminsActionSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class AdminsActionFailure extends AdminsState {
  const AdminsActionFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
