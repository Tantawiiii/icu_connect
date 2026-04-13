import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/network_exceptions.dart';
import '../repository/hospitals_repository.dart';
import 'hospitals_state.dart';

class HospitalsCubit extends Cubit<HospitalsState> {
  HospitalsCubit() : super(const HospitalsInitial());

  final _repo = const HospitalsRepository();

  Future<void> fetchHospitals({int page = 1}) async {
    emit(const HospitalsLoading());
    try {
      final response = await _repo.fetchHospitals(page: page);
      emit(HospitalsLoaded(response.data, response.pagination));
    } on NetworkException catch (e) {
      emit(HospitalsFailure(e.message));
    } catch (_) {
      emit(const HospitalsFailure('An unexpected error occurred'));
    }
  }

  Future<void> deleteHospital(int id) async {
    final current = state;
    if (current is! HospitalsLoaded) return;

    emit(HospitalsActionLoading(current.hospitals, current.pagination));
    try {
      await _repo.deleteHospital(id);
      final updated =
          current.hospitals.where((h) => h.id != id).toList();
      emit(HospitalsActionSuccess(
        updated,
        current.pagination,
        'Hospital deleted successfully',
      ));
    } on NetworkException catch (e) {
      emit(HospitalsActionFailure(current.hospitals, current.pagination, e.message));
    } catch (_) {
      emit(HospitalsActionFailure(
        current.hospitals,
        current.pagination,
        'An unexpected error occurred',
      ));
    }
  }

  Future<void> restoreHospital(int id) async {
    final current = state;
    if (current is! HospitalsLoaded) return;

    emit(HospitalsActionLoading(current.hospitals, current.pagination));
    try {
      final restored = await _repo.restoreHospital(id);
      final updated = current.hospitals
          .map((h) => h.id == id ? restored : h)
          .toList();
      emit(HospitalsActionSuccess(
        updated,
        current.pagination,
        'Hospital restored successfully',
      ));
    } on NetworkException catch (e) {
      emit(HospitalsActionFailure(current.hospitals, current.pagination, e.message));
    } catch (_) {
      emit(HospitalsActionFailure(
        current.hospitals,
        current.pagination,
        'An unexpected error occurred',
      ));
    }
  }
}
