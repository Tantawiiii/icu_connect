import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/services/base_api_service.dart';
import '../models/hospital_model.dart';
import '../models/hospital_request_model.dart';
import '../models/hospital_requests_list_response.dart';
import '../models/hospitals_list_response.dart';

class HospitalsRepository extends BaseApiService {
  const HospitalsRepository() : super(UserRole.admin);

  /// GET /hospitals?per_page=10&page=1
  Future<HospitalsListResponse> fetchHospitals({
    int perPage = 10,
    int page = 1,
  }) async {
    final data = await get<Map<String, dynamic>>(
      ApiConstants.hospitals,
      queryParameters: {'per_page': perPage, 'page': page},
      cancelTag: 'hospitals_list_$page',
    );
    return HospitalsListResponse.fromJson(data);
  }

  /// POST /hospitals
  Future<HospitalModel> createHospital(HospitalRequest request) async {
    final data = await post<Map<String, dynamic>>(
      ApiConstants.hospitals,
      data: request.toCreateJson(),
      cancelTag: 'hospital_create',
    );
    return HospitalModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// PUT /hospitals/{id}
  Future<HospitalModel> updateHospital(int id, HospitalRequest request) async {
    final data = await put<Map<String, dynamic>>(
      ApiConstants.hospitalById(id),
      data: request.toUpdateJson(),
      cancelTag: 'hospital_update_$id',
    );
    return HospitalModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// DELETE /hospitals/{id}
  Future<void> deleteHospital(int id) async {
    await delete<dynamic>(
      ApiConstants.hospitalById(id),
      cancelTag: 'hospital_delete_$id',
    );
  }

  /// POST /hospitals/{id}/restore
  Future<HospitalModel> restoreHospital(int id) async {
    final data = await post<Map<String, dynamic>>(
      ApiConstants.hospitalRestore(id),
      cancelTag: 'hospital_restore_$id',
    );
    return HospitalModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// GET /hospitals/requests?approval_status=pending|accepted|rejected
  Future<HospitalRequestsListResponse> fetchHospitalRequests({
    String? approvalStatus,
    int perPage = 10,
    int page = 1,
  }) async {
    final query = <String, dynamic>{'per_page': perPage, 'page': page};
    if (approvalStatus != null && approvalStatus.trim().isNotEmpty) {
      query['approval_status'] = approvalStatus.trim();
    }
    final data = await get<Map<String, dynamic>>(
      ApiConstants.hospitalsRequests,
      queryParameters: query,
      cancelTag: 'hospital_requests_${approvalStatus ?? 'all'}_$page',
    );
    return HospitalRequestsListResponse.fromJson(data);
  }

  /// POST /hospitals/{id}/accept
  Future<void> acceptHospitalRequest(int id) async {
    await post<dynamic>(
      ApiConstants.hospitalAccept(id),
      cancelTag: 'hospital_request_accept_$id',
    );
  }

  /// POST /hospitals/{id}/reject
  Future<void> rejectHospitalRequest(int id) async {
    await post<dynamic>(
      ApiConstants.hospitalReject(id),
      cancelTag: 'hospital_request_reject_$id',
    );
  }
}
