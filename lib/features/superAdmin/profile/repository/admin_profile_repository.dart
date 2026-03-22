import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/services/base_api_service.dart';
import '../models/admin_profile_response.dart';

class AdminProfileRepository extends BaseApiService {
  const AdminProfileRepository() : super(UserRole.admin);

  /// GET /auth/profile
  Future<AdminProfileResponse> fetchProfile() async {
    try {
      final data = await get<Map<String, dynamic>>(
        ApiConstants.authProfile,
        cancelTag: 'admin_profile',
      );
      return AdminProfileResponse.fromJson(data);
    } on NetworkException {
      rethrow;
    }
  }
}
