import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../login/models/admin_model.dart';
import '../models/pagination_model.dart';
import '../repository/admins_repository.dart';
import 'admins_state.dart';

class AdminsCubit extends Cubit<AdminsState> {
  AdminsCubit(this._repository) : super(const AdminsInitial());

  final AdminsRepository _repository;

  List<AdminModel> _admins = [];
  PaginationModel? _pagination;

  Future<void> fetchAdmins() async {
    emit(const AdminsLoading());
    try {
      final response = await _repository.fetchAdmins();
      _admins = response.data;
      _pagination = response.pagination;
      emit(AdminsLoaded(admins: _admins, pagination: _pagination!));
    } on NetworkException catch (e) {
      emit(AdminsFailure(e.message));
    } catch (_) {
      emit(const AdminsFailure('An unexpected error occurred.'));
    }
  }

  Future<void> deleteAdmin(int id) async {
    emit(const AdminsActionLoading());
    try {
      await _repository.deleteAdmin(id);
      // Remove locally and re-emit success then refresh
      _admins = _admins.where((a) => a.id != id).toList();
      emit(const AdminsActionSuccess('Admin deleted successfully'));
      // Re-fetch to get accurate list from server
      await fetchAdmins();
    } on NetworkException catch (e) {
      emit(AdminsActionFailure(e.message));
      // Restore previous list state
      if (_pagination != null) {
        emit(AdminsLoaded(admins: _admins, pagination: _pagination!));
      }
    } catch (_) {
      emit(const AdminsActionFailure('Failed to delete admin.'));
      if (_pagination != null) {
        emit(AdminsLoaded(admins: _admins, pagination: _pagination!));
      }
    }
  }
}
