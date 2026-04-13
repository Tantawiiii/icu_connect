import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/services/base_api_service.dart';
import '../models/admin_dashboard_model.dart';

class AdminDashboardRepository extends BaseApiService {
  const AdminDashboardRepository() : super(UserRole.admin);

  Future<AdminDashboardData> fetchDashboard() async {
    try {
      final body = await get<Map<String, dynamic>>(
        ApiConstants.dashboard,
        cancelTag: 'admin_dashboard',
      );
      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw const NetworkException(message: 'Invalid dashboard response.');
      }
      return AdminDashboardData.fromJson(data);
    } on NetworkException {
      rethrow;
    }
  }
}
