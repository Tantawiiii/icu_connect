import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_texts.dart';
import '../../../../core/network/network_exceptions.dart';
import '../models/vital_title_request.dart';
import '../repository/vitals_titles_repository.dart';
import 'vitals_titles_state.dart';

class VitalsTitlesCubit extends Cubit<VitalsTitlesState> {
  VitalsTitlesCubit() : super(const VitalsTitlesInitial());

  final _repo = const VitalsTitlesRepository();

  Future<void> fetchVitalsTitles({int page = 1}) async {
    emit(const VitalsTitlesLoading());
    try {
      final result = await _repo.fetchVitalsTitles(page: page);
      emit(VitalsTitlesLoaded(result.items, result.pagination));
    } on NetworkException catch (e) {
      emit(VitalsTitlesFailure(e.message));
    } catch (_) {
      emit(const VitalsTitlesFailure('An unexpected error occurred'));
    }
  }

  Future<void> createVitalTitle(VitalTitleRequest request) async {
    emit(const VitalsTitlesLoading());
    try {
      await _repo.createVitalTitle(request);
      final result = await _repo.fetchVitalsTitles(page: 1);
      emit(VitalsTitlesLoaded(result.items, result.pagination));
    } on NetworkException catch (e) {
      emit(VitalsTitlesFailure(e.message));
    } catch (_) {
      emit(const VitalsTitlesFailure('An unexpected error occurred'));
    }
  }

  Future<void> updateVitalTitle(int id, VitalTitleRequest request) async {
    final current = state;
    if (current is! VitalsTitlesLoaded) return;

    emit(VitalsTitlesActionLoading(current.items, current.pagination));
    try {
      final updated = await _repo.updateVitalTitle(id, request);
      final items =
          current.items.map((e) => e.id == id ? updated : e).toList();
      emit(VitalsTitlesActionSuccess(
        items,
        current.pagination,
        AppTexts.vitalTitleUpdated,
      ));
    } on NetworkException catch (e) {
      emit(VitalsTitlesActionFailure(current.items, current.pagination, e.message));
    } catch (_) {
      emit(VitalsTitlesActionFailure(
        current.items,
        current.pagination,
        'An unexpected error occurred',
      ));
    }
  }

  Future<void> deleteVitalTitle(int id) async {
    final current = state;
    if (current is! VitalsTitlesLoaded) return;

    emit(VitalsTitlesActionLoading(current.items, current.pagination));
    try {
      await _repo.deleteVitalTitle(id);
      final items = current.items.where((e) => e.id != id).toList();
      emit(VitalsTitlesActionSuccess(
        items,
        current.pagination,
        AppTexts.vitalTitleDeleted,
      ));
    } on NetworkException catch (e) {
      emit(VitalsTitlesActionFailure(current.items, current.pagination, e.message));
    } catch (_) {
      emit(VitalsTitlesActionFailure(
        current.items,
        current.pagination,
        'An unexpected error occurred',
      ));
    }
  }
}

