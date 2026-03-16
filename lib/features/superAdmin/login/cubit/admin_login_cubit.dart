import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/network_exceptions.dart';
import '../repository/admin_auth_repository.dart';
import 'admin_login_state.dart';

class AdminLoginCubit extends Cubit<AdminLoginState> {
  AdminLoginCubit(this._repository) : super(const AdminLoginInitial());

  final AdminAuthRepository _repository;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    if (state is AdminLoginLoading) return;

    emit(const AdminLoginLoading());

    try {
      final response = await _repository.login(
        email: email,
        password: password,
      );
      emit(AdminLoginSuccess(response));
    } on NetworkException catch (e) {
      emit(AdminLoginFailure(e.message));
    } catch (e) {
      emit(AdminLoginFailure('An unexpected error occurred.'));
    }
  }

  void reset() => emit(const AdminLoginInitial());
}
