import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_texts.dart';
import '../../../../core/network/network_exceptions.dart';
import '../models/drug_model.dart';
import '../models/drug_request.dart';
import '../repository/drugs_repository.dart';
import 'drugs_state.dart';

class DrugsCubit extends Cubit<DrugsState> {
  DrugsCubit() : super(const DrugsInitial());

  final _repo = const DrugsRepository();

  DrugsListFilter _filter = DrugsListFilter.all;
  String _search = '';

  Future<void> fetchDrugs({int page = 1}) async {
    emit(const DrugsLoading());
    try {
      final result = await _repo.fetchDrugs(
        page: page,
        search: _search,
        isActive: _isActiveParam(_filter),
        archivedOnly: _filter == DrugsListFilter.archived,
      );
      emit(DrugsLoaded(
        result.items,
        result.pagination,
        filter: _filter,
        search: _search,
      ));
    } on NetworkException catch (e) {
      emit(DrugsFailure(e.message));
    } catch (_) {
      emit(const DrugsFailure('An unexpected error occurred'));
    }
  }

  Future<void> setFilter(DrugsListFilter filter) async {
    if (_filter == filter) return;
    _filter = filter;
    await fetchDrugs(page: 1);
  }

  Future<void> search(String query) async {
    _search = query.trim();
    await fetchDrugs(page: 1);
  }

  /// Flat active formulary for dropdowns / medical forms (no pagination).
  Future<List<DrugModel>> fetchFormulary({String? search}) {
    return _repo.fetchFormulary(search: search);
  }

  Future<void> createDrug(DrugRequest request) async {
    emit(const DrugsLoading());
    try {
      await _repo.createDrug(request);
      final result = await _repo.fetchDrugs(
        page: 1,
        search: _search,
        isActive: _isActiveParam(_filter),
        archivedOnly: _filter == DrugsListFilter.archived,
      );
      emit(DrugsActionSuccess(
        result.items,
        result.pagination,
        AppTexts.drugCreated,
        filter: _filter,
        search: _search,
      ));
    } on NetworkException catch (e) {
      emit(DrugsFailure(e.message));
    } catch (_) {
      emit(const DrugsFailure('An unexpected error occurred'));
    }
  }

  Future<void> updateDrug(int id, DrugRequest request) async {
    final current = state;
    if (current is! DrugsLoaded) return;

    emit(DrugsActionLoading(
      current.items,
      current.pagination,
      filter: current.filter,
      search: current.search,
    ));
    try {
      final updated = await _repo.updateDrug(id, request);
      final items =
          current.items.map((e) => e.id == id ? updated : e).toList();
      emit(DrugsActionSuccess(
        items,
        current.pagination,
        AppTexts.drugUpdated,
        filter: current.filter,
        search: current.search,
      ));
    } on NetworkException catch (e) {
      emit(DrugsActionFailure(
        current.items,
        current.pagination,
        e.message,
        filter: current.filter,
        search: current.search,
      ));
    } catch (_) {
      emit(DrugsActionFailure(
        current.items,
        current.pagination,
        'An unexpected error occurred',
        filter: current.filter,
        search: current.search,
      ));
    }
  }

  Future<void> archiveDrug(int id) async {
    final current = state;
    if (current is! DrugsLoaded) return;

    emit(DrugsActionLoading(
      current.items,
      current.pagination,
      filter: current.filter,
      search: current.search,
    ));
    try {
      await _repo.archiveDrug(id);
      final items = current.items.where((e) => e.id != id).toList();
      emit(DrugsActionSuccess(
        items,
        current.pagination,
        AppTexts.drugArchived,
        filter: current.filter,
        search: current.search,
      ));
    } on NetworkException catch (e) {
      emit(DrugsActionFailure(
        current.items,
        current.pagination,
        e.message,
        filter: current.filter,
        search: current.search,
      ));
    } catch (_) {
      emit(DrugsActionFailure(
        current.items,
        current.pagination,
        'An unexpected error occurred',
        filter: current.filter,
        search: current.search,
      ));
    }
  }

  Future<void> restoreDrug(int id) async {
    final current = state;
    if (current is! DrugsLoaded) return;

    emit(DrugsActionLoading(
      current.items,
      current.pagination,
      filter: current.filter,
      search: current.search,
    ));
    try {
      await _repo.restoreDrug(id);
      final items = current.items.where((e) => e.id != id).toList();
      emit(DrugsActionSuccess(
        items,
        current.pagination,
        AppTexts.drugRestored,
        filter: current.filter,
        search: current.search,
      ));
    } on NetworkException catch (e) {
      emit(DrugsActionFailure(
        current.items,
        current.pagination,
        e.message,
        filter: current.filter,
        search: current.search,
      ));
    } catch (_) {
      emit(DrugsActionFailure(
        current.items,
        current.pagination,
        'An unexpected error occurred',
        filter: current.filter,
        search: current.search,
      ));
    }
  }

  bool? _isActiveParam(DrugsListFilter filter) {
    switch (filter) {
      case DrugsListFilter.active:
        return true;
      case DrugsListFilter.inactive:
        return false;
      case DrugsListFilter.all:
      case DrugsListFilter.archived:
        return null;
    }
  }
}
