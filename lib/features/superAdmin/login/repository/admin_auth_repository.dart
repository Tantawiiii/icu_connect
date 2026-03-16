import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/services/base_api_service.dart';
import '../../../../core/network/token_storage.dart';
import '../models/admin_login_response.dart';


class AdminAuthRepository extends BaseApiService {
  const AdminAuthRepository() : super(UserRole.admin);

  Future<AdminLoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final data = await post<Map<String, dynamic>>(
        ApiConstants.login,
        data: {'email': email, 'password': password},
        cancelTag: 'admin_login',
      );

      final response = AdminLoginResponse.fromJson(data);

      await TokenStorage.instance.saveAccessToken(response.data.accessToken);
      await TokenStorage.instance.saveRefreshToken(response.data.refreshToken);
      await TokenStorage.instance.saveUserRole(UserRole.admin.name);

      return response;
    } on NetworkException {
      rethrow;
    }
  }


  Future<void> logout() async {
    try {
      await post<void>(ApiConstants.logout, cancelTag: 'admin_logout');
    } finally {
      await TokenStorage.instance.clearAll();
      ApiClient.reset();
    }
  }
}
