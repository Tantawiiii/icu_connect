import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_constants.dart';
import '../../../../../core/network/network_exceptions.dart';
import '../../../../../core/network/services/base_api_service.dart';
import '../models/doctor_hospital.dart';
import '../models/doctor_hospital_creation_request.dart';
import '../../../superAdmin/hospitals/models/hospital_registration_request_model.dart';

class DoctorHospitalsRepository extends BaseApiService {
  const DoctorHospitalsRepository() : super(UserRole.hospital);

  Future<List<DoctorHospital>> fetchHospitals() async {
    try {
      final data = await get<Map<String, dynamic>>(
        ApiConstants.authHospitals,
        cancelTag: 'doctor_auth_hospitals',
      );
      final raw = data['data'] as List<dynamic>?;
      if (raw == null) return [];
      return raw
          .map((e) => DoctorHospital.fromJson(e as Map<String, dynamic>))
          .toList();
    } on NetworkException {
      rethrow;
    }
  }

  /// POST /hospitals/request
  Future<void> submitHospitalRequest(DoctorHospitalCreationRequest request) async {
    try {
      await post<dynamic>(
        ApiConstants.hospitalsRequest,
        data: request.toJson(),
        cancelTag: 'doctor_hospital_request_submit',
      );
    } on NetworkException {
      rethrow;
    }
  }

  /// GET /hospitals/requests
  Future<List<HospitalRegistrationRequest>> fetchMyHospitalRequests() async {
    try {
      final data = await get<Map<String, dynamic>>(
        ApiConstants.hospitalsRequests,
        cancelTag: 'doctor_hospital_requests',
      );
      final raw = data['data'];
      if (raw is! List<dynamic>) return [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(HospitalRegistrationRequest.fromJson)
          .toList();
    } on NetworkException {
      rethrow;
    }
  }
}
