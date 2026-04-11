import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/network_exceptions.dart';
import '../repository/users_repository.dart';
import 'users_state.dart';

class UsersCubit extends Cubit<UsersState> {
  UsersCubit() : super(const UsersInitial());

  final _repo = const UsersRepository();

  Future<void> fetchUsers({int page = 1}) async {
    emit(const UsersLoading());
    try {
      final response = await _repo.fetchUsers(page: page);
      emit(UsersLoaded(response.data, response.pagination));
    } on NetworkException catch (e) {
      emit(UsersFailure(e.message));
    } catch (_) {
      emit(const UsersFailure('An unexpected error occurred'));
    }
  }

  Future<void> deleteUser(int id) async {
    final current = state;
    if (current is! UsersLoaded) return;

    emit(UsersActionLoading(current.users, current.pagination));
    try {
      await _repo.deleteUser(id);
      final updated = current.users.where((u) => u.id != id).toList();
      emit(UsersActionSuccess(
        updated,
        current.pagination,
        'User deleted successfully',
      ));
    } on NetworkException catch (e) {
      emit(UsersActionFailure(current.users, current.pagination, e.message));
    } catch (_) {
      emit(UsersActionFailure(
        current.users,
        current.pagination,
        'An unexpected error occurred',
      ));
    }
  }

  Future<void> restoreUser(int id) async {
    final current = state;
    if (current is! UsersLoaded) return;

    emit(UsersActionLoading(current.users, current.pagination));
    try {
      final restored = await _repo.restoreUser(id);
      final updated =
          current.users.map((u) => u.id == id ? restored : u).toList();
      emit(UsersActionSuccess(
        updated,
        current.pagination,
        'User restored successfully',
      ));
    } on NetworkException catch (e) {
      emit(UsersActionFailure(current.users, current.pagination, e.message));
    } catch (_) {
      emit(UsersActionFailure(
        current.users,
        current.pagination,
        'An unexpected error occurred',
      ));
    }
  }
}
