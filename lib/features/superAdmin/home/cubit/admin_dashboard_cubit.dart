import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/network_exceptions.dart';
import '../repository/admin_dashboard_repository.dart';
import 'admin_dashboard_state.dart';

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit({AdminDashboardRepository? repository})
      : _repository = repository ?? const AdminDashboardRepository(),
        super(const AdminDashboardInitial());

  final AdminDashboardRepository _repository;

  Future<void> fetchDashboard() async {
    emit(const AdminDashboardLoading());
    try {
      final data = await _repository.fetchDashboard();
      emit(AdminDashboardLoaded(data));
    } on NetworkException catch (e) {
      emit(AdminDashboardFailure(e.message));
    } catch (_) {
      emit(const AdminDashboardFailure('An unexpected error occurred'));
    }
  }
}
