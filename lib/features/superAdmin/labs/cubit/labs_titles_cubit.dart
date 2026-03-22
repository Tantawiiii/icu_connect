import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_texts.dart';
import '../../../../core/network/network_exceptions.dart';
import '../models/lab_title_request.dart';
import '../repository/labs_titles_repository.dart';
import 'labs_titles_state.dart';

class LabsTitlesCubit extends Cubit<LabsTitlesState> {
  LabsTitlesCubit() : super(const LabsTitlesInitial());

  final _repo = const LabsTitlesRepository();

  Future<void> fetchLabsTitles() async {
    emit(const LabsTitlesLoading());
    try {
      final items = await _repo.fetchLabsTitles();
      emit(LabsTitlesLoaded(items));
    } on NetworkException catch (e) {
      emit(LabsTitlesFailure(e.message));
    } catch (_) {
      emit(const LabsTitlesFailure('An unexpected error occurred'));
    }
  }

  Future<void> createLabTitle(LabTitleRequest request) async {
    emit(const LabsTitlesLoading());
    try {
      await _repo.createLabTitle(request);
      emit(const LabsTitlesLoading());
      final items = await _repo.fetchLabsTitles();
      emit(LabsTitlesLoaded(items));
    } on NetworkException catch (e) {
      emit(LabsTitlesFailure(e.message));
    } catch (_) {
      emit(const LabsTitlesFailure('An unexpected error occurred'));
    }
  }

  Future<void> updateLabTitle(int id, LabTitleRequest request) async {
    final current = state;
    if (current is! LabsTitlesLoaded) return;

    emit(LabsTitlesActionLoading(current.items));
    try {
      final updated = await _repo.updateLabTitle(id, request);
      final items = current.items
          .map((e) => e.id == id ? updated : e)
          .toList();
      emit(LabsTitlesActionSuccess(items, AppTexts.labTitleUpdated));
    } on NetworkException catch (e) {
      emit(LabsTitlesActionFailure(current.items, e.message));
    } catch (_) {
      emit(LabsTitlesActionFailure(
          current.items, 'An unexpected error occurred'));
    }
  }

  Future<void> deleteLabTitle(int id) async {
    final current = state;
    if (current is! LabsTitlesLoaded) return;

    emit(LabsTitlesActionLoading(current.items));
    try {
      await _repo.deleteLabTitle(id);
      final items = current.items.where((e) => e.id != id).toList();
      emit(LabsTitlesActionSuccess(items, AppTexts.labTitleDeleted));
    } on NetworkException catch (e) {
      emit(LabsTitlesActionFailure(current.items, e.message));
    } catch (_) {
      emit(LabsTitlesActionFailure(
          current.items, 'An unexpected error occurred'));
    }
  }
}

