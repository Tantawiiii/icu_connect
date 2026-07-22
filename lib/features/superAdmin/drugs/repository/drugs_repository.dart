import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/services/base_api_service.dart';
import '../../admins/models/pagination_model.dart';
import '../models/drug_model.dart';
import '../models/drug_request.dart';
import '../models/drugs_page_result.dart';

class DrugsRepository extends BaseApiService {
  const DrugsRepository() : super(UserRole.admin);

  /// GET /drugs
  Future<DrugsPageResult> fetchDrugs({
    int page = 1,
    int perPage = 15,
    String? search,
    bool? isActive,
    bool archivedOnly = false,
    bool includeArchived = false,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      final q = search?.trim() ?? '';
      if (q.isNotEmpty) query['search'] = q;
      if (isActive != null) query['is_active'] = isActive;
      if (archivedOnly) query['archived'] = true;
      if (includeArchived) query['include_archived'] = true;

      final data = await get<Map<String, dynamic>>(
        ApiConstants.drugs,
        queryParameters: query,
        cancelTag: 'drugs_list_$page',
      );
      return _parsePage(data);
    } on NetworkException {
      rethrow;
    }
  }

  /// GET /drugs/{id}
  Future<DrugModel> fetchDrug(int id) async {
    try {
      final data = await get<Map<String, dynamic>>(
        ApiConstants.drugById(id),
        cancelTag: 'drug_details_$id',
      );
      return DrugModel.fromJson(data['data'] as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    }
  }

  /// GET /drugs/formulary — flat active list, no pagination (for dropdowns).
  Future<List<DrugModel>> fetchFormulary({String? search}) async {
    try {
      final query = <String, dynamic>{};
      final q = search?.trim() ?? '';
      if (q.isNotEmpty) query['search'] = q;

      final data = await get<Map<String, dynamic>>(
        ApiConstants.drugsFormulary,
        queryParameters: query.isEmpty ? null : query,
        cancelTag: 'drugs_formulary',
      );

      final raw = data['data'];
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(DrugModel.fromJson)
            .toList();
      }
      return const [];
    } on NetworkException {
      rethrow;
    }
  }

  /// POST /drugs
  Future<DrugModel> createDrug(DrugRequest request) async {
    try {
      final data = await post<Map<String, dynamic>>(
        ApiConstants.drugs,
        data: request.toJson(),
        cancelTag: 'drugs_create',
      );
      return DrugModel.fromJson(data['data'] as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    }
  }

  /// PUT /drugs/{id}
  Future<DrugModel> updateDrug(int id, DrugRequest request) async {
    try {
      final data = await put<Map<String, dynamic>>(
        ApiConstants.drugById(id),
        data: request.toJson(),
        cancelTag: 'drugs_update_$id',
      );
      return DrugModel.fromJson(data['data'] as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    }
  }

  /// DELETE /drugs/{id} (same as archive)
  Future<void> archiveDrug(int id) async {
    try {
      await delete<dynamic>(
        ApiConstants.drugById(id),
        cancelTag: 'drugs_archive_$id',
      );
    } on NetworkException {
      rethrow;
    }
  }

  /// POST /drugs/{id}/restore
  Future<DrugModel> restoreDrug(int id) async {
    try {
      final data = await post<Map<String, dynamic>>(
        ApiConstants.drugRestore(id),
        cancelTag: 'drugs_restore_$id',
      );
      return DrugModel.fromJson(data['data'] as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    }
  }

  DrugsPageResult _parsePage(Map<String, dynamic> data) {
    final raw = data['data'];

    if (raw is List) {
      final items = raw
          .whereType<Map<String, dynamic>>()
          .map(DrugModel.fromJson)
          .toList();
      return DrugsPageResult(
        items: items,
        pagination: PaginationModel(
          currentPage: 1,
          from: items.isEmpty ? 0 : 1,
          to: items.length,
          total: items.length,
          perPage: items.isEmpty ? 15 : items.length,
          lastPage: 1,
        ),
      );
    }

    if (raw is Map<String, dynamic>) {
      final list = (raw['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DrugModel.fromJson)
          .toList();
      return DrugsPageResult(
        items: list,
        pagination: PaginationModel.fromJson(raw),
      );
    }

    return const DrugsPageResult(
      items: [],
      pagination: PaginationModel(
        currentPage: 1,
        from: 0,
        to: 0,
        total: 0,
        perPage: 15,
        lastPage: 1,
      ),
    );
  }
}
