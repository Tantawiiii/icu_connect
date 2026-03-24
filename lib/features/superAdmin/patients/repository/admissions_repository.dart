import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/services/base_api_service.dart';
import '../models/admission_request_model.dart';
import '../models/patient_admission_models.dart';

class AdmissionsRepository extends BaseApiService {
  const AdmissionsRepository() : super(UserRole.admin);

  /// POST /admissions
  Future<PatientAdmissionModel> createAdmission(
    AdmissionCreateRequest request,
  ) async {
    try {
      if (request.needsMultipart) {
        final fd = await request.toFormData();
        final data = await upload<Map<String, dynamic>>(
          ApiConstants.admissions,
          fd,
          cancelTag: 'admission_create',
        );
        return PatientAdmissionModel.fromJson(
            data['data'] as Map<String, dynamic>);
      }
      final data = await post<Map<String, dynamic>>(
        ApiConstants.admissions,
        data: request.toJson(),
        cancelTag: 'admission_create',
      );
      return PatientAdmissionModel.fromJson(
          data['data'] as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    }
  }

  /// PUT /admissions/{id}
  Future<PatientAdmissionModel> updateAdmission(
    int id,
    AdmissionUpdateRequest request,
  ) async {
    try {
      if (request.needsMultipart) {
        final fd = await request.toFormData();
        final data = await uploadPut<Map<String, dynamic>>(
          ApiConstants.admissionById(id),
          fd,
          cancelTag: 'admission_update_$id',
        );
        return PatientAdmissionModel.fromJson(
            data['data'] as Map<String, dynamic>);
      }
      final data = await put<Map<String, dynamic>>(
        ApiConstants.admissionById(id),
        data: request.toJson(),
        cancelTag: 'admission_update_$id',
      );
      return PatientAdmissionModel.fromJson(
          data['data'] as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    }
  }

  /// DELETE /admissions/{id}
  Future<void> deleteAdmission(int id) async {
    try {
      await delete<dynamic>(
        ApiConstants.admissionById(id),
        cancelTag: 'admission_delete_$id',
      );
    } on NetworkException {
      rethrow;
    }
  }
}
