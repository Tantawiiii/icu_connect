import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_constants.dart';
import '../../../../../core/network/network_exceptions.dart';
import '../../../../../core/network/services/base_api_service.dart';
import '../../auth/signup/models/signup_hospital_item.dart';
import '../models/doctor_profile.dart';

class DoctorProfileRepository extends BaseApiService {
  const DoctorProfileRepository() : super(UserRole.hospital);

  Future<DoctorProfile> fetchProfile() async {
    try {
      final data = await get<Map<String, dynamic>>(
        ApiConstants.authProfile,
        cancelTag: 'doctor_profile_get',
      );
      final inner = data['data'] as Map<String, dynamic>?;
      if (inner == null) {
        throw const NetworkException(message: 'Invalid profile response.');
      }
      return DoctorProfile.fromJson(inner);
    } on NetworkException {
      rethrow;
    }
  }

  Future<List<SignupHospitalItem>> fetchHospitalCatalog() async {
    try {
      final data = await get<Map<String, dynamic>>(
        ApiConstants.authListHospitals,
        cancelTag: 'doctor_profile_list_hospitals',
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

  Future<DoctorProfile> updateProfile({
    required String name,
    required String email,
    required String phone,
    required List<int> hospitalIds,
    String? password,
    String? passwordConfirmation,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'email': email,
        'phone': phone,
        'hospitals':
            hospitalIds.map((id) => <String, dynamic>{'hospital_id': id}).toList(),
      };
      final pwd = password?.trim() ?? '';
      if (pwd.isNotEmpty) {
        body['password'] = pwd;
        body['password_confirmation'] =
            (passwordConfirmation?.trim().isNotEmpty ?? false)
                ? passwordConfirmation!.trim()
                : pwd;
      }

      final data = await put<Map<String, dynamic>>(
        ApiConstants.authProfile,
        data: body,
        cancelTag: 'doctor_profile_put',
      );
      final inner = data['data'] as Map<String, dynamic>?;
      if (inner == null) {
        throw const NetworkException(message: 'Invalid profile update response.');
      }
      return DoctorProfile.fromJson(inner);
    } on NetworkException {
      rethrow;
    }
  }

  /// `DELETE /auth/profile` — delete the authenticated user's account.
  Future<void> deleteAccount() async {
    try {
      await deleteWithoutBody(
        ApiConstants.authProfile,
        cancelTag: 'doctor_profile_delete_account',
      );
    } on NetworkException {
      rethrow;
    }
  }
}
