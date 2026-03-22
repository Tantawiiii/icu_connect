import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/network_exceptions.dart';
import '../models/hospital_request_model.dart';
import '../repository/hospitals_repository.dart';
import 'hospital_form_state.dart';

class HospitalFormCubit extends Cubit<HospitalFormState> {
  HospitalFormCubit() : super(const HospitalFormInitial());

  final _repo = const HospitalsRepository();

  Future<void> createHospital(HospitalRequest request) async {
    emit(const HospitalFormLoading());
    try {
      await _repo.createHospital(request);
      emit(const HospitalFormSuccess('Hospital created successfully'));
    } on NetworkException catch (e) {
      emit(HospitalFormFailure(e.message));
    } catch (_) {
      emit(const HospitalFormFailure('An unexpected error occurred'));
    }
  }

  Future<void> updateHospital(int id, HospitalRequest request) async {
    emit(const HospitalFormLoading());
    try {
      await _repo.updateHospital(id, request);
      emit(const HospitalFormSuccess('Hospital updated successfully'));
    } on NetworkException catch (e) {
      emit(HospitalFormFailure(e.message));
    } catch (_) {
      emit(const HospitalFormFailure('An unexpected error occurred'));
    }
  }
}
