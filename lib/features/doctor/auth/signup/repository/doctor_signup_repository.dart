import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_constants.dart';
import '../../../../../core/network/network_exceptions.dart';
import '../../../../../core/network/services/base_api_service.dart';
import '../models/doctor_signup_response.dart';
import '../models/signup_hospital_item.dart';

class DoctorSignupRepository extends BaseApiService {
  const DoctorSignupRepository() : super(UserRole.hospital);

  Future<List<SignupHospitalItem>> fetchHospitals() async {
    try {
      final data = await get<Map<String, dynamic>>(
        ApiConstants.authListHospitals,
        cancelTag: 'doctor_list_hospitals',
      );
      final raw = data['data'] as List<dynamic>?;
      if (raw == null) return [];
      return raw
          .map((e) => SignupHospitalItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on NetworkException {
      rethrow;
    }
  }

  Future<DoctorSignupResponse> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required int hospitalId,
  }) async {
    try {
      final data = await post<Map<String, dynamic>>(
        ApiConstants.signup,
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'hospitals': [
            {'hospital_id': hospitalId},
          ],
        },
        cancelTag: 'doctor_signup',
      );
      return DoctorSignupResponse.fromJson(data);
    } on NetworkException {
      rethrow;
    }
  }
}
