import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/services/base_api_service.dart';
import '../../admins/models/pagination_model.dart';
import '../models/vital_title_model.dart';
import '../models/vital_title_request.dart';
import '../models/vitals_titles_page_result.dart';

class VitalsTitlesRepository extends BaseApiService {
  const VitalsTitlesRepository() : super(UserRole.admin);

  /// GET /vitals-titles?per_page=10&page=1
  Future<VitalsTitlesPageResult> fetchVitalsTitles({
    int perPage = 10,
    int page = 1,
  }) async {
    try {
      final data = await get<Map<String, dynamic>>(
        ApiConstants.vitalsTitles,
        queryParameters: {
          'per_page': perPage,
          'page': page,
        },
        cancelTag: 'vitals_titles_list_$page',
      );
      final inner = data['data'] as Map<String, dynamic>;
      final list = inner['data'] as List<dynamic>;
      final items = list
          .map((e) => VitalTitleModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final pagination = PaginationModel.fromJson(inner);
      return VitalsTitlesPageResult(items: items, pagination: pagination);
    } on NetworkException {
      rethrow;
    }
  }

  /// POST /vitals-titles
  Future<VitalTitleModel> createVitalTitle(VitalTitleRequest request) async {
    try {
      final data = await post<Map<String, dynamic>>(
        ApiConstants.vitalsTitles,
        data: request.toJson(),
        cancelTag: 'vitals_titles_create',
      );
      return VitalTitleModel.fromJson(data['data'] as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    }
  }

  /// PUT /vitals-titles/{id}
  Future<VitalTitleModel> updateVitalTitle(
      int id, VitalTitleRequest request) async {
    try {
      final data = await put<Map<String, dynamic>>(
        ApiConstants.vitalTitleById(id),
        data: request.toJson(),
        cancelTag: 'vitals_titles_update_$id',
      );
      return VitalTitleModel.fromJson(data['data'] as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    }
  }

  /// DELETE /vitals-titles/{id}
  Future<void> deleteVitalTitle(int id) async {
    try {
      await delete<dynamic>(
        ApiConstants.vitalTitleById(id),
        cancelTag: 'vitals_titles_delete_$id',
      );
    } on NetworkException {
      rethrow;
    }
  }
}

