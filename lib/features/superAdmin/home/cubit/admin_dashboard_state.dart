import 'package:equatable/equatable.dart';

import '../models/admin_dashboard_model.dart';

sealed class AdminDashboardState extends Equatable {
  const AdminDashboardState();

  @override
  List<Object?> get props => [];
}

class AdminDashboardInitial extends AdminDashboardState {
  const AdminDashboardInitial();
}

class AdminDashboardLoading extends AdminDashboardState {
  const AdminDashboardLoading();
}

class AdminDashboardLoaded extends AdminDashboardState {
  const AdminDashboardLoaded(this.data);
  final AdminDashboardData data;

  @override
  List<Object?> get props => [data];
}

class AdminDashboardFailure extends AdminDashboardState {
  const AdminDashboardFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
