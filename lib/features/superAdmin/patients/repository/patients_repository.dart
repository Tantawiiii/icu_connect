import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/services/base_api_service.dart';
import '../models/patient_model.dart';
import '../models/patient_request_model.dart';
import '../models/patients_list_response.dart';

class PatientsRepository extends BaseApiService {
  const PatientsRepository() : super(UserRole.admin);

  /// GET /patients?per_page=10
  Future<PatientsListResponse> fetchPatients({int perPage = 10}) async {
    try {
      final data = await get<Map<String, dynamic>>(
        ApiConstants.patients,
        queryParameters: {'per_page': perPage},
        cancelTag: 'patients_list',
      );
      return PatientsListResponse.fromJson(data);
    } on NetworkException {
      rethrow;
    }
  }

  /// GET /patients/{id}
  Future<PatientModel> fetchPatientById(int id) async {
    try {
      final data = await get<Map<String, dynamic>>(
        ApiConstants.patientById(id.toString()),
        cancelTag: 'patient_$id',
      );
      return PatientModel.fromJson(data['data'] as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    }
  }

  /// POST /patients
  Future<PatientModel> createPatient(PatientRequest request) async {
    try {
      final data = await post<Map<String, dynamic>>(
        ApiConstants.patients,
        data: request.toJson(),
        cancelTag: 'patient_create',
      );
      return PatientModel.fromJson(data['data'] as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    }
  }

  /// PUT /patients/{id}
  Future<PatientModel> updatePatient(int id, PatientRequest request) async {
    try {
      final data = await put<Map<String, dynamic>>(
        ApiConstants.patientById(id.toString()),
        data: request.toJson(),
        cancelTag: 'patient_update_$id',
      );
      return PatientModel.fromJson(data['data'] as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    }
  }

  /// DELETE /patients/{id}
  Future<void> deletePatient(int id) async {
    try {
      await delete<dynamic>(
        ApiConstants.patientById(id.toString()),
        cancelTag: 'patient_delete_$id',
      );
    } on NetworkException {
      rethrow;
    }
  }
}

