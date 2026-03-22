import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/network_exceptions.dart';
import '../models/user_request_model.dart';
import '../repository/users_repository.dart';
import 'user_form_state.dart';

class UserFormCubit extends Cubit<UserFormState> {
  UserFormCubit() : super(const UserFormInitial());

  final _repo = const UsersRepository();

  Future<void> createUser(UserRequest request) async {
    emit(const UserFormLoading());
    try {
      await _repo.createUser(request);
      emit(const UserFormSuccess('User created successfully'));
    } on NetworkException catch (e) {
      emit(UserFormFailure(e.message));
    } catch (_) {
      emit(const UserFormFailure('An unexpected error occurred'));
    }
  }

  Future<void> updateUser(int id, UserRequest request) async {
    emit(const UserFormLoading());
    try {
      await _repo.updateUser(id, request);
      emit(const UserFormSuccess('User updated successfully'));
    } on NetworkException catch (e) {
      emit(UserFormFailure(e.message));
    } catch (_) {
      emit(const UserFormFailure('An unexpected error occurred'));
    }
  }
}
