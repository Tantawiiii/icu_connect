import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/network_exceptions.dart';
import '../repository/users_repository.dart';
import 'users_state.dart';

class UsersCubit extends Cubit<UsersState> {
  UsersCubit() : super(const UsersInitial());

  final _repo = const UsersRepository();

  Future<void> fetchUsers() async {
    emit(const UsersLoading());
    try {
      final response = await _repo.fetchUsers();
      emit(UsersLoaded(response.data));
    } on NetworkException catch (e) {
      emit(UsersFailure(e.message));
    } catch (_) {
      emit(const UsersFailure('An unexpected error occurred'));
    }
  }

  Future<void> deleteUser(int id) async {
    final current = state;
    if (current is! UsersLoaded) return;

    emit(UsersActionLoading(current.users));
    try {
      await _repo.deleteUser(id);
      final updated = current.users.where((u) => u.id != id).toList();
      emit(UsersActionSuccess(updated, 'User deleted successfully'));
    } on NetworkException catch (e) {
      emit(UsersActionFailure(current.users, e.message));
    } catch (_) {
      emit(UsersActionFailure(current.users, 'An unexpected error occurred'));
    }
  }

  Future<void> restoreUser(int id) async {
    final current = state;
    if (current is! UsersLoaded) return;

    emit(UsersActionLoading(current.users));
    try {
      final restored = await _repo.restoreUser(id);
      final updated =
          current.users.map((u) => u.id == id ? restored : u).toList();
      emit(UsersActionSuccess(updated, 'User restored successfully'));
    } on NetworkException catch (e) {
      emit(UsersActionFailure(current.users, e.message));
    } catch (_) {
      emit(UsersActionFailure(current.users, 'An unexpected error occurred'));
    }
  }
}
