import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/services/base_api_service.dart';
import '../../login/models/admin_model.dart';
import '../models/admin_request_model.dart';
import '../models/admins_list_response.dart';

class AdminsRepository extends BaseApiService {
  const AdminsRepository() : super(UserRole.admin);

  /// GET /admins?per_page=20&page=1
  Future<AdminsListResponse> fetchAdmins({
    int perPage = 20,
    int page = 1,
  }) async {
    final data = await get<Map<String, dynamic>>(
      ApiConstants.admins,
      queryParameters: {'per_page': perPage, 'page': page},
      cancelTag: 'admins_list_$page',
    );
    return AdminsListResponse.fromJson(data);
  }

  /// POST /admins
  Future<AdminModel> createAdmin(AdminRequest request) async {
    final data = await post<Map<String, dynamic>>(
      ApiConstants.admins,
      data: request.toJson(),
      cancelTag: 'admin_create',
    );
    return AdminModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// PUT /admins/{id}
  Future<AdminModel> updateAdmin(int id, AdminRequest request) async {
    final data = await put<Map<String, dynamic>>(
      ApiConstants.adminById(id),
      data: request.toJson(),
      cancelTag: 'admin_update_$id',
    );
    return AdminModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// DELETE /admins/{id}
  Future<void> deleteAdmin(int id) async {
    await delete<dynamic>(
      ApiConstants.adminById(id),
      cancelTag: 'admin_delete_$id',
    );
  }
}
