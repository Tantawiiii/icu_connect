import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_constants.dart';
import '../../../../../core/network/network_exceptions.dart';
import '../../../../../core/network/services/base_api_service.dart';
import '../models/doctor_hospital.dart';

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
}
