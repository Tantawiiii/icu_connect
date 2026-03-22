import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/network_exceptions.dart';
import '../models/admin_request_model.dart';
import '../repository/admins_repository.dart';
import 'admin_form_state.dart';

class AdminFormCubit extends Cubit<AdminFormState> {
  AdminFormCubit(this._repository) : super(const AdminFormInitial());

  final AdminsRepository _repository;

  Future<void> createAdmin(AdminRequest request) async {
    if (state is AdminFormLoading) return;
    emit(const AdminFormLoading());
    try {
      final admin = await _repository.createAdmin(request);
      emit(AdminFormSuccess(admin: admin, message: 'Admin created successfully'));
    } on NetworkException catch (e) {
      emit(AdminFormFailure(e.message));
    } catch (_) {
      emit(const AdminFormFailure('An unexpected error occurred.'));
    }
  }

  Future<void> updateAdmin(int id, AdminRequest request) async {
    if (state is AdminFormLoading) return;
    emit(const AdminFormLoading());
    try {
      final admin = await _repository.updateAdmin(id, request);
      emit(AdminFormSuccess(admin: admin, message: 'Admin updated successfully'));
    } on NetworkException catch (e) {
      emit(AdminFormFailure(e.message));
    } catch (_) {
      emit(const AdminFormFailure('An unexpected error occurred.'));
    }
  }
}
