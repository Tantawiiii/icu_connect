import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_texts.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../hospitals/repository/hospitals_repository.dart';
import '../../labs/repository/labs_titles_repository.dart';
import '../../users/repository/users_repository.dart';
import '../../vitals/repository/vitals_titles_repository.dart';
import '../models/admission_request_model.dart';
import '../repository/admissions_repository.dart';
import 'admission_form_state.dart';

class AdminAdmissionFormCubit extends Cubit<AdminAdmissionFormState> {
  AdminAdmissionFormCubit() : super(const AdminAdmissionFormInitial());

  /// Non-null after reference data has loaded successfully.
  AdminAdmissionFormRefsReady? get refs => _refs;

  final _admissions = const AdmissionsRepository();
  final _hospitals = const HospitalsRepository();
  final _users = const UsersRepository();
  final _vitalsTitles = const VitalsTitlesRepository();
  final _labsTitles = const LabsTitlesRepository();

  Future<void> loadReferenceData() async {
    emit(const AdminAdmissionFormLoadingRefs());
    try {
      final hospitalsFuture = _hospitals.fetchHospitals(perPage: 100);
      final usersFuture = _users.fetchUsers(perPage: 100);
      final vitalsFuture = _vitalsTitles.fetchVitalsTitles(perPage: 100);
      final labsFuture = _labsTitles.fetchLabsTitles();

      final hospitalsRes = await hospitalsFuture;
      final usersRes = await usersFuture;
      final vitalTitles = await vitalsFuture;
      final labTitles = await labsFuture;

      _refs = AdminAdmissionFormRefsReady(
        hospitals: hospitalsRes.data,
        users: usersRes.data,
        vitalTitles: vitalTitles.items,
        labTitles: labTitles,
      );
      emit(_refs!);
    } on NetworkException catch (e) {
      emit(AdminAdmissionFormFailure(e.message));
    } catch (_) {
      emit(const AdminAdmissionFormFailure('Failed to load form data'));
    }
  }

  AdminAdmissionFormRefsReady? _refs;

  Future<void> createAdmission(AdmissionCreateRequest request) async {
    if (_refs == null) return;
    emit(const AdminAdmissionFormSubmitting());
    try {
      await _admissions.createAdmission(request);
      emit(const AdminAdmissionFormSuccess(AppTexts.admissionCreated));
    } on NetworkException catch (e) {
      emit(AdminAdmissionFormFailure(e.message));
    } catch (_) {
      emit(const AdminAdmissionFormFailure('An unexpected error occurred'));
    }
  }

  Future<void> updateAdmission(int id, AdmissionUpdateRequest request) async {
    if (_refs == null) return;
    emit(const AdminAdmissionFormSubmitting());
    try {
      await _admissions.updateAdmission(id, request);
      emit(const AdminAdmissionFormSuccess(AppTexts.admissionUpdated));
    } on NetworkException catch (e) {
      emit(AdminAdmissionFormFailure(e.message));
    } catch (_) {
      emit(const AdminAdmissionFormFailure('An unexpected error occurred'));
    }
  }
}
