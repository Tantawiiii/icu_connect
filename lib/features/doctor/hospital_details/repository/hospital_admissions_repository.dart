import 'package:dio/dio.dart';
import 'package:icu_connect/core/network/api_client.dart';
import 'package:icu_connect/core/network/api_constants.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/core/network/services/base_api_service.dart';

import '../../../superAdmin/patients/models/patient_admission_models.dart';
import '../../../superAdmin/patients/models/patient_model.dart';
import '../../patients/models/hospital_patients_page_result.dart';
import '../enums/admission_activity_subject_type.dart';
import '../models/admission_activity.dart';
import '../models/admission_timeline_note.dart';
import '../utils/measurement_title_order.dart';
import '../../../../core/utils/measurement_title_form_helpers.dart';

class HospitalAdmissionsRepository extends BaseApiService {
  const HospitalAdmissionsRepository() : super(UserRole.hospital);

  Future<List<PatientAdmissionModel>> listAdmissions({
    required int hospitalId,
    required String status,
  }) async {
    try {
      final data = await get<Map<String, dynamic>>(
        ApiConstants.admissions,
        queryParameters: {'hospital_id': hospitalId, 'status': status},
        cancelTag: 'hospital_admissions_list_${hospitalId}_$status',
      );

      final raw = data['data'] as List<dynamic>? ?? const [];
      return raw
          .map((e) => PatientAdmissionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on NetworkException {
      rethrow;
    }
  }

  /// Fetches improved, deceased, and DAMA admissions for the hospital.
  Future<List<PatientAdmissionModel>> listDischargedOutcomeAdmissions({
    required int hospitalId,
  }) async {
    final batches = await Future.wait([
      listAdmissions(hospitalId: hospitalId, status: 'discharged'),
      listAdmissions(hospitalId: hospitalId, status: 'deceased'),
      listAdmissions(hospitalId: hospitalId, status: 'leaves_ama'),
    ]);

    final byId = <int, PatientAdmissionModel>{};
    for (final batch in batches) {
      for (final admission in batch) {
        byId[admission.id] = admission;
      }
    }
    return byId.values.toList();
  }

  Future<PatientAdmissionModel> getAdmission(int admissionId) async {
    try {
      final data = await get<Map<String, dynamic>>(
        ApiConstants.admissionById(admissionId),
        cancelTag: 'hospital_admissions_details_$admissionId',
      );
      return PatientAdmissionModel.fromJson(
        data['data'] as Map<String, dynamic>,
      );
    } on NetworkException {
      rethrow;
    }
  }

  Future<List<AdmissionActivity>> fetchAdmissionActivity(
    int admissionId, {
    AdmissionActivitySubjectType? subjectType,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (subjectType != null) {
        queryParameters['subject_type'] = subjectType.apiValue;
      }

      final data = await get<Map<String, dynamic>>(
        ApiConstants.admissionActivity(admissionId),
        queryParameters:
            queryParameters.isEmpty ? null : queryParameters,
        cancelTag:
            'hospital_admissions_activity_${admissionId}_${subjectType?.apiValue ?? 'all'}',
      );

      final raw = data['data'];
      final List<dynamic> list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic>) {
        list = raw['activities'] as List<dynamic>? ??
            raw['activity'] as List<dynamic>? ??
            const [];
      } else {
        list = const [];
      }

      return list
          .whereType<Map<String, dynamic>>()
          .map(AdmissionActivity.fromJson)
          .toList();
    } on NetworkException {
      rethrow;
    }
  }

  /// GET /admissions/{id}/notes
  Future<List<AdmissionTimelineNote>> fetchAdmissionNotes(
    int admissionId,
  ) async {
    try {
      final data = await get<Map<String, dynamic>>(
        ApiConstants.admissionNotes(admissionId),
        cancelTag: 'hospital_admission_notes_$admissionId',
      );
      final raw = data['data'];
      if (raw is! List) return const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(AdmissionTimelineNote.fromJson)
          .toList();
    } on NetworkException {
      rethrow;
    }
  }

  /// POST /admissions/{id}/notes
  Future<AdmissionTimelineNote> createAdmissionNote(
    int admissionId, {
    required String content,
  }) async {
    try {
      final data = await post<Map<String, dynamic>>(
        ApiConstants.admissionNotes(admissionId),
        data: {'content': content.trim()},
        cancelTag: 'hospital_admission_notes_create_$admissionId',
      );
      return AdmissionTimelineNote.fromJson(
        data['data'] as Map<String, dynamic>,
      );
    } on NetworkException {
      rethrow;
    }
  }

  Future<void> createAdmission(FormData formData) async {
    try {
      await upload<Map<String, dynamic>>(
        ApiConstants.admissions,
        formData,
        cancelTag: 'hospital_admissions_create',
      );
    } on NetworkException {
      rethrow;
    }
  }

  Future<void> updateAdmission(int id, FormData formData) async {
    try {
      await upload<Map<String, dynamic>>(
        ApiConstants.admissionById(id),
        formData,
        cancelTag: 'hospital_admissions_update_$id',
      );
    } on NetworkException {
      rethrow;
    }
  }

  /// Updates admission fields via raw JSON body (no FormData required).
  Future<void> updateAdmissionRaw(int id, Map<String, dynamic> body) async {
    try {
      await post<Map<String, dynamic>>(
        ApiConstants.admissionById(id),
        data: body,
        cancelTag: 'hospital_admissions_update_raw_$id',
      );
    } on NetworkException {
      rethrow;
    }
  }

  Future<void> deleteAdmission(int id) async {
    try {
      await delete<Map<String, dynamic>>(
        ApiConstants.admissionById(id),
        cancelTag: 'hospital_admissions_delete_$id',
      );
    } on NetworkException {
      rethrow;
    }
  }

  Future<void> swapBeds({
    required int firstAdmissionId,
    required int secondAdmissionId,
  }) async {
    try {
      await post<Map<String, dynamic>>(
        ApiConstants.admissionsSwapBeds,
        data: {
          'first_admission_id': firstAdmissionId,
          'second_admission_id': secondAdmissionId,
        },
        cancelTag:
            'hospital_admissions_swap_${firstAdmissionId}_$secondAdmissionId',
      );
    } on NetworkException {
      rethrow;
    }
  }

  Future<List<AdmissionPatientModel>> listPatients({
    int perPage = 10,
    bool archived = false,
    String? nationalId,
  }) async {
    final page = await listPatientsPage(
      page: 1,
      perPage: perPage,
      archived: archived,
      nationalId: nationalId,
    );
    return page.patients;
  }

  Future<HospitalPatientsPageResult> listPatientsPage({
    int page = 1,
    int perPage = 15,
    bool archived = false,
    String? nationalId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        'archived': archived,
      };
      if (nationalId != null && nationalId.isNotEmpty) {
        queryParams['national_id'] = nationalId;
      }

      final data = await get<Map<String, dynamic>>(
        ApiConstants.patients,
        queryParameters: queryParams,
        cancelTag: 'hospital_patients_list_$page',
      );

      final raw = data['data'] as List<dynamic>? ?? const [];
      final patients = raw
          .map((e) => AdmissionPatientModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final pagination = data['pagination'] as Map<String, dynamic>?;
      final current = (pagination?['current_page'] as num?)?.toInt() ?? page;
      final last = (pagination?['last_page'] as num?)?.toInt() ?? 1;
      final total = (pagination?['total'] as num?)?.toInt() ?? patients.length;

      return HospitalPatientsPageResult(
        patients: patients,
        currentPage: current,
        lastPage: last,
        total: total,
      );
    } on NetworkException {
      rethrow;
    }
  }

  Future<PatientModel> getPatient(int id) async {
    try {
      final data = await get<Map<String, dynamic>>(
        ApiConstants.patientById('$id'),
        cancelTag: 'hospital_patient_get_$id',
      );
      return PatientModel.fromJson(data['data'] as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    }
  }

  Future<PatientModel> createPatient({
    required String name,
    required String nationalId,
    required int age,
    required String gender,
    required String phone,
    required String bloodGroup,
    required String notes,
  }) async {
    try {
      final data = await post<Map<String, dynamic>>(
        ApiConstants.patients,
        data: {
          'name': name,
          'national_id': nationalId,
          'age': age,
          'gender': gender,
          'phone': phone,
          'blood_group': bloodGroup,
          'notes': notes,
        },
        cancelTag: 'hospital_patient_create',
      );
      return PatientModel.fromJson(data['data'] as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    }
  }

  Future<PatientModel> updatePatient({
    required int id,
    required String name,
    required String nationalId,
    required int age,
    required String gender,
    required String phone,
    required String bloodGroup,
    required String notes,
  }) async {
    try {
      final data = await put<Map<String, dynamic>>(
        ApiConstants.patientById('$id'),
        data: {
          'name': name,
          'national_id': nationalId,
          'age': age,
          'gender': gender,
          'phone': phone,
          'blood_group': bloodGroup,
          'notes': notes,
        },
        cancelTag: 'hospital_patient_update_$id',
      );
      return PatientModel.fromJson(data['data'] as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    }
  }

  Future<void> deletePatient(int id) async {
    try {
      await delete<dynamic>(
        ApiConstants.patientById('$id'),
        cancelTag: 'hospital_patient_delete_$id',
      );
    } on NetworkException {
      rethrow;
    }
  }

  Future<List<MeasurementTitleModel>> listPatientVitalsTitles(
    int patientId,
  ) async {
    try {
      final data = await get<Map<String, dynamic>>(
        ApiConstants.patientVitalsTitles(patientId),
        cancelTag: 'hospital_patient_vitals_titles_$patientId',
      );

      final raw = data['data'];
      final List<dynamic> list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic>) {
        list = raw['data'] as List<dynamic>? ?? const [];
      } else {
        list = const [];
      }

      return MeasurementTitleOrder.sortVitals(
        list
            .whereType<Map<String, dynamic>>()
            .map(MeasurementTitleModel.fromJson)
            .toList(),
      );
    } on NetworkException {
      rethrow;
    }
  }

  Future<MeasurementTitleModel> createPatientVitalTitle({
    required int patientId,
    required String title,
    String? unit,
    String valueType = 'numeric',
    double? normalRangeMin,
    double? normalRangeMax,
  }) async {
    try {
      final body = MeasurementTitleFormValues(
        title: title,
        unit: unit,
        valueType: valueType,
        normalRangeMin: normalRangeMin,
        normalRangeMax: normalRangeMax,
      ).toVitalJson();

      final data = await post<Map<String, dynamic>>(
        ApiConstants.patientVitalsTitles(patientId),
        data: body,
        cancelTag: 'hospital_patient_vitals_title_create_$patientId',
      );

      final raw = data['data'];
      if (raw is Map<String, dynamic>) {
        return MeasurementTitleModel.fromJson(raw);
      }
      throw const NetworkException(message: 'Invalid vital title response');
    } on NetworkException {
      rethrow;
    }
  }

  Future<List<MeasurementTitleModel>> listPatientLabsTitles(int patientId) async {
    try {
      final data = await get<Map<String, dynamic>>(
        ApiConstants.patientLabsTitles(patientId),
        cancelTag: 'hospital_patient_labs_titles_$patientId',
      );

      final raw = data['data'];
      final List<dynamic> list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic>) {
        list = raw['data'] as List<dynamic>? ?? const [];
      } else {
        list = const [];
      }

      return MeasurementTitleOrder.sortLabs(
        list
            .whereType<Map<String, dynamic>>()
            .map(MeasurementTitleModel.fromJson)
            .toList(),
      );
    } on NetworkException {
      rethrow;
    }
  }

  Future<MeasurementTitleModel> createPatientLabTitle({
    required int patientId,
    required String title,
    String? unit,
    String valueType = 'numeric',
    double? normalRangeMin,
    double? normalRangeMax,
  }) async {
    try {
      final body = MeasurementTitleFormValues(
        title: title,
        unit: unit,
        valueType: valueType,
        normalRangeMin: normalRangeMin,
        normalRangeMax: normalRangeMax,
      ).toLabJson();

      final data = await post<Map<String, dynamic>>(
        ApiConstants.patientLabsTitles(patientId),
        data: body,
        cancelTag: 'hospital_patient_labs_title_create_$patientId',
      );

      final raw = data['data'];
      if (raw is Map<String, dynamic>) {
        return MeasurementTitleModel.fromJson(raw);
      }
      throw const NetworkException(message: 'Invalid lab title response');
    } on NetworkException {
      rethrow;
    }
  }

  Future<List<MeasurementTitleModel>> listVitalsTitles() async {
    try {
      final data = await get<Map<String, dynamic>>(
        ApiConstants.vitalsTitles,
        cancelTag: 'hospital_vitals_titles_list',
      );

      final raw = data['data'] as List<dynamic>? ?? const [];
      return MeasurementTitleOrder.sortVitals(
        raw
            .map((e) => MeasurementTitleModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on NetworkException {
      rethrow;
    }
  }

  Future<List<MeasurementTitleModel>> listLabsTitles() async {
    try {
      final data = await get<Map<String, dynamic>>(
        ApiConstants.labsTitles,
        cancelTag: 'hospital_labs_titles_list',
      );

      final raw = data['data'] as List<dynamic>? ?? const [];
      return MeasurementTitleOrder.sortLabs(
        raw
            .map((e) => MeasurementTitleModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on NetworkException {
      rethrow;
    }
  }
}
