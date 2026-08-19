import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/network_exceptions.dart';
import '../repository/hospitals_repository.dart';
import 'hospital_requests_state.dart';

class HospitalRequestsCubit extends Cubit<HospitalRequestsState> {
  HospitalRequestsCubit() : super(const HospitalRequestsInitial());

  final _repo = const HospitalsRepository();

  Future<void> fetchRequests({String? approvalStatus, int page = 1}) async {
    emit(const HospitalRequestsLoading());
    try {
      final response = await _repo.fetchHospitalRequests(
        approvalStatus: approvalStatus,
        page: page,
      );
      emit(
        HospitalRequestsLoaded(
          response.data,
          response.pagination,
          approvalStatus,
        ),
      );
    } on NetworkException catch (e) {
      emit(HospitalRequestsFailure(e.message));
    } catch (_) {
      emit(const HospitalRequestsFailure('An unexpected error occurred'));
    }
  }

  Future<void> acceptRequest(int id) async {
    final current = state;
    if (current is! HospitalRequestsLoaded) return;

    emit(
      HospitalRequestsActionLoading(
        current.requests,
        current.pagination,
        current.approvalStatusFilter,
      ),
    );
    try {
      await _repo.acceptHospitalRequest(id);
      final updated = current.requests.where((r) => r.id != id).toList();
      emit(
        HospitalRequestsActionSuccess(
          updated,
          current.pagination,
          current.approvalStatusFilter,
          'Hospital request accepted successfully',
        ),
      );
    } on NetworkException catch (e) {
      emit(
        HospitalRequestsActionFailure(
          current.requests,
          current.pagination,
          current.approvalStatusFilter,
          e.message,
        ),
      );
    } catch (_) {
      emit(
        HospitalRequestsActionFailure(
          current.requests,
          current.pagination,
          current.approvalStatusFilter,
          'An unexpected error occurred',
        ),
      );
    }
  }

  Future<void> rejectRequest(int id) async {
    final current = state;
    if (current is! HospitalRequestsLoaded) return;

    emit(
      HospitalRequestsActionLoading(
        current.requests,
        current.pagination,
        current.approvalStatusFilter,
      ),
    );
    try {
      await _repo.rejectHospitalRequest(id);
      final updated = current.requests.where((r) => r.id != id).toList();
      emit(
        HospitalRequestsActionSuccess(
          updated,
          current.pagination,
          current.approvalStatusFilter,
          'Hospital request rejected successfully',
        ),
      );
    } on NetworkException catch (e) {
      emit(
        HospitalRequestsActionFailure(
          current.requests,
          current.pagination,
          current.approvalStatusFilter,
          e.message,
        ),
      );
    } catch (_) {
      emit(
        HospitalRequestsActionFailure(
          current.requests,
          current.pagination,
          current.approvalStatusFilter,
          'An unexpected error occurred',
        ),
      );
    }
  }
}
