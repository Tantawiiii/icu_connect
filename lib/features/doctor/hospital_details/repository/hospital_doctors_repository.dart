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

  /// Doctors with `status=pending` (nested `hospitals[]` per doctor when applicable).
  Future<List<HospitalDoctor>> fetchPendingDoctorsPool(int hospitalId) async {
    try {
      final data = await get<Map<String, dynamic>>(
        ApiConstants.hospitalDoctors(hospitalId),
        queryParameters: const {'status': 'pending'},
        cancelTag: 'hospital_doctors_pending_pool_$hospitalId',
      );
      final inner = data['data'] as Map<String, dynamic>?;
      final raw = inner?['doctors'] as List<dynamic>?;
      if (raw == null) return [];
      return raw
          .map(
            (e) => HospitalDoctor.fromJson(
              e as Map<String, dynamic>,
              forHospitalId: hospitalId,
            ),
          )
          .toList();
    } on NetworkException {
      rethrow;
    }
  }

  /// Inactive doctors with pending hospital membership (`status=pending&is_active=false`).
  Future<List<HospitalDoctor>> fetchInactivePendingDoctorRequests(
    int hospitalId,
  ) async {
    try {
      final data = await get<Map<String, dynamic>>(
        ApiConstants.hospitalDoctors(hospitalId),
        queryParameters: const {
          'status': 'pending',
          'is_active': false,
        },
        cancelTag: 'hospital_doctors_inactive_pending_$hospitalId',
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

  Future<void> addDoctorToHospital({
    required int hospitalId,
    required int doctorId,
  }) async {
    try {
      await post<Map<String, dynamic>>(
        ApiConstants.hospitalDoctorsAdd(hospitalId),
        data: {'doctor_id': doctorId},
        cancelTag: 'hospital_add_doctor_${hospitalId}_$doctorId',
      );
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

}

