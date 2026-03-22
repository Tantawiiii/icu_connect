import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/services/base_api_service.dart';
import '../../login/models/admin_model.dart';
import '../models/admin_request_model.dart';
import '../models/admins_list_response.dart';

class AdminsRepository extends BaseApiService {
  const AdminsRepository() : super(UserRole.admin);

  /// GET /admins
  Future<AdminsListResponse> fetchAdmins() async {
    try {
      final data = await get<Map<String, dynamic>>(
        ApiConstants.admins,
        cancelTag: 'admins_list',
      );
      return AdminsListResponse.fromJson(data);
    } on NetworkException {
      rethrow;
    }
  }

  /// POST /admins
  Future<AdminModel> createAdmin(AdminRequest request) async {
    try {
      final data = await post<Map<String, dynamic>>(
        ApiConstants.admins,
        data: request.toJson(),
        cancelTag: 'admin_create',
      );
      return AdminModel.fromJson(data['data'] as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    }
  }

  /// PUT /admins/{id}
  Future<AdminModel> updateAdmin(int id, AdminRequest request) async {
    try {
      final data = await put<Map<String, dynamic>>(
        ApiConstants.adminById(id),
        data: request.toJson(),
        cancelTag: 'admin_update_$id',
      );
      return AdminModel.fromJson(data['data'] as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    }
  }

  /// DELETE /admins/{id}
  Future<void> deleteAdmin(int id) async {
    try {
      await delete<dynamic>(
        ApiConstants.adminById(id),
        cancelTag: 'admin_delete_$id',
      );
    } on NetworkException {
      rethrow;
    }
  }
}
