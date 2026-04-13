import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/services/base_api_service.dart';
import '../models/user_model.dart';
import '../models/user_request_model.dart';
import '../models/users_list_response.dart';

class UsersRepository extends BaseApiService {
  const UsersRepository() : super(UserRole.admin);

  /// GET /users?per_page=10&page=1
  Future<UsersListResponse> fetchUsers({
    int perPage = 10,
    int page = 1,
  }) async {
    try {
      final data = await get<Map<String, dynamic>>(
        ApiConstants.users,
        queryParameters: {'per_page': perPage, 'page': page},
        cancelTag: 'users_list_$page',
      );
      return UsersListResponse.fromJson(data);
    } on NetworkException {
      rethrow;
    }
  }

  /// POST /users
  Future<UserModel> createUser(UserRequest request) async {
    try {
      final data = await post<Map<String, dynamic>>(
        ApiConstants.users,
        data: request.toJson(),
        cancelTag: 'user_create',
      );
      return UserModel.fromJson(data['data'] as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    }
  }

  /// PUT /users/{id}
  Future<UserModel> updateUser(int id, UserRequest request) async {
    try {
      final data = await put<Map<String, dynamic>>(
        ApiConstants.userById(id),
        data: request.toJson(),
        cancelTag: 'user_update_$id',
      );
      return UserModel.fromJson(data['data'] as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    }
  }

  /// DELETE /users/{id}
  Future<void> deleteUser(int id) async {
    try {
      await delete<dynamic>(
        ApiConstants.userById(id),
        cancelTag: 'user_delete_$id',
      );
    } on NetworkException {
      rethrow;
    }
  }

  /// POST /users/{id}/restore
  Future<UserModel> restoreUser(int id) async {
    try {
      final data = await post<Map<String, dynamic>>(
        ApiConstants.userRestore(id),
        cancelTag: 'user_restore_$id',
      );
      return UserModel.fromJson(data['data'] as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    }
  }
}
