import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/network_exceptions.dart';
import '../repository/admin_profile_repository.dart';
import 'admin_profile_state.dart';

class AdminProfileCubit extends Cubit<AdminProfileState> {
  AdminProfileCubit(this._repository) : super(const AdminProfileInitial());

  final AdminProfileRepository _repository;

  Future<void> fetchProfile() async {
    if (state is AdminProfileLoading) return;
    emit(const AdminProfileLoading());
    try {
      final response = await _repository.fetchProfile();
      emit(AdminProfileSuccess(response.data));
    } on NetworkException catch (e) {
      emit(AdminProfileFailure(e.message));
    } catch (_) {
      emit(const AdminProfileFailure('An unexpected error occurred.'));
    }
  }
}
