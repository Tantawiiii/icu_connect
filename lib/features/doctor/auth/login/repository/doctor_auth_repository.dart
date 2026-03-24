import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_constants.dart';
import '../../../../../core/network/network_exceptions.dart';
import '../../../../../core/network/services/base_api_service.dart';
import '../../../../../core/network/token_storage.dart';

import '../models/doctor_login_response.dart';

class DoctorAuthRepository extends BaseApiService {
  const DoctorAuthRepository() : super(UserRole.hospital);

  Future<DoctorLoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final data = await post<Map<String, dynamic>>(
        ApiConstants.login,
        data: {'email': email, 'password': password},
        cancelTag: 'doctor_login',
      );

      final response = DoctorLoginResponse.fromJson(data);

      await TokenStorage.instance.saveAccessToken(response.data.accessToken);
      await TokenStorage.instance.saveRefreshToken(response.data.refreshToken);
      await TokenStorage.instance.saveUserRole(UserRole.hospital.name);

      return response;
    } on NetworkException {
      rethrow;
    }
  }

  Future<bool> hasSession() async {
    final accessToken = await TokenStorage.instance.getAccessToken();
    final refreshToken = await TokenStorage.instance.getRefreshToken();
    final role = await TokenStorage.instance.getUserRole();

    return accessToken != null &&
        accessToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty &&
        role == UserRole.hospital.name;
  }
}
