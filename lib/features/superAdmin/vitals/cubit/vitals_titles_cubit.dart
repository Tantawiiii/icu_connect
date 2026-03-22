import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_texts.dart';
import '../../../../core/network/network_exceptions.dart';
import '../models/vital_title_request.dart';
import '../repository/vitals_titles_repository.dart';
import 'vitals_titles_state.dart';

class VitalsTitlesCubit extends Cubit<VitalsTitlesState> {
  VitalsTitlesCubit() : super(const VitalsTitlesInitial());

  final _repo = const VitalsTitlesRepository();

  Future<void> fetchVitalsTitles() async {
    emit(const VitalsTitlesLoading());
    try {
      final items = await _repo.fetchVitalsTitles();
      emit(VitalsTitlesLoaded(items));
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
      final items = await _repo.fetchVitalsTitles();
      emit(VitalsTitlesLoaded(items));
    } on NetworkException catch (e) {
      emit(VitalsTitlesFailure(e.message));
    } catch (_) {
      emit(const VitalsTitlesFailure('An unexpected error occurred'));
    }
  }

  Future<void> updateVitalTitle(int id, VitalTitleRequest request) async {
    final current = state;
    if (current is! VitalsTitlesLoaded) return;

    emit(VitalsTitlesActionLoading(current.items));
    try {
      final updated = await _repo.updateVitalTitle(id, request);
      final items =
          current.items.map((e) => e.id == id ? updated : e).toList();
      emit(VitalsTitlesActionSuccess(items, AppTexts.vitalTitleUpdated));
    } on NetworkException catch (e) {
      emit(VitalsTitlesActionFailure(current.items, e.message));
    } catch (_) {
      emit(VitalsTitlesActionFailure(
          current.items, 'An unexpected error occurred'));
    }
  }

  Future<void> deleteVitalTitle(int id) async {
    final current = state;
    if (current is! VitalsTitlesLoaded) return;

    emit(VitalsTitlesActionLoading(current.items));
    try {
      await _repo.deleteVitalTitle(id);
      final items = current.items.where((e) => e.id != id).toList();
      emit(VitalsTitlesActionSuccess(items, AppTexts.vitalTitleDeleted));
    } on NetworkException catch (e) {
      emit(VitalsTitlesActionFailure(current.items, e.message));
    } catch (_) {
      emit(VitalsTitlesActionFailure(
          current.items, 'An unexpected error occurred'));
    }
  }
}

