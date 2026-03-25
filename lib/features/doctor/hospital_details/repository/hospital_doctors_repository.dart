import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/network/api_constants.dart';
import '../../../../../../core/network/network_exceptions.dart';
import '../../../../../../core/network/services/base_api_service.dart';
import '../models/hospital_doctor.dart';

class HospitalDoctorsRepository extends BaseApiService {
  const HospitalDoctorsRepository() : super(UserRole.hospital);

  Future<List<HospitalDoctor>> fetchDoctors(int hospitalId) async {
    try {
      final data = await get<Map<String, dynamic>>(
        ApiConstants.hospitalDoctors(hospitalId),
        cancelTag: 'hospital_doctors_$hospitalId',
      );
      final inner = data['data'] as Map<String, dynamic>?;
      final raw = inner?['doctors'] as List<dynamic>?;
      if (raw == null) return [];
      return raw
          .map((e) => HospitalDoctor.fromJson(e as Map<String, dynamic>))
          .toList();
    } on NetworkException {
      rethrow;
    }
  }

  Future<void> acceptDoctor({
    required int hospitalId,
    required int doctorId,
  }) async {
    try {
      await post<Map<String, dynamic>>(
        ApiConstants.hospitalAcceptDoctor(hospitalId),
        data: {'doctor_id': doctorId},
        cancelTag: 'hospital_accept_doctor_${hospitalId}_$doctorId',
      );
    } on NetworkException {
      rethrow;
    }
  }

  Future<void> activateDoctor(int doctorId) async {
    try {
      await post<Map<String, dynamic>>(
        ApiConstants.doctorActivate(doctorId),
        cancelTag: 'doctor_activate_$doctorId',
      );
    } on NetworkException {
      rethrow;
    }
  }

  Future<void> createDoctor({
    required int hospitalId,
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await post<Map<String, dynamic>>(
        ApiConstants.hospitalDoctors(hospitalId),
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
        cancelTag: 'hospital_create_doctor_$hospitalId',
      );
    } on NetworkException {
      rethrow;
    }
  }
}

