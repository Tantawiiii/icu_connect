import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/services/base_api_service.dart';
import '../models/hospital_model.dart';
import '../models/hospital_request_model.dart';
import '../models/hospitals_list_response.dart';

class HospitalsRepository extends BaseApiService {
  const HospitalsRepository() : super(UserRole.admin);

  /// GET /hospitals?per_page=10&page=1
  Future<HospitalsListResponse> fetchHospitals({
    int perPage = 10,
    int page = 1,
  }) async {
    try {
      final data = await get<Map<String, dynamic>>(
        ApiConstants.hospitals,
        queryParameters: {'per_page': perPage, 'page': page},
        cancelTag: 'hospitals_list_$page',
      );
      return HospitalsListResponse.fromJson(data);
    } on NetworkException {
      rethrow;
    }
  }

  /// POST /hospitals
  Future<HospitalModel> createHospital(HospitalRequest request) async {
    try {
      final data = await post<Map<String, dynamic>>(
        ApiConstants.hospitals,
        data: request.toCreateJson(),
        cancelTag: 'hospital_create',
      );
      return HospitalModel.fromJson(data['data'] as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    }
  }

  /// PUT /hospitals/{id}
  Future<HospitalModel> updateHospital(int id, HospitalRequest request) async {
    try {
      final data = await put<Map<String, dynamic>>(
        ApiConstants.hospitalById(id),
        data: request.toUpdateJson(),
        cancelTag: 'hospital_update_$id',
      );
      return HospitalModel.fromJson(data['data'] as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    }
  }

  /// DELETE /hospitals/{id}
  Future<void> deleteHospital(int id) async {
    try {
      await delete<dynamic>(
        ApiConstants.hospitalById(id),
        cancelTag: 'hospital_delete_$id',
      );
    } on NetworkException {
      rethrow;
    }
  }

  /// POST /hospitals/{id}/restore
  Future<HospitalModel> restoreHospital(int id) async {
    try {
      final data = await post<Map<String, dynamic>>(
        ApiConstants.hospitalRestore(id),
        cancelTag: 'hospital_restore_$id',
      );
      return HospitalModel.fromJson(data['data'] as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    }
  }
}
