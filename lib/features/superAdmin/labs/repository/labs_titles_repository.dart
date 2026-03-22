import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/services/base_api_service.dart';
import '../models/lab_title_model.dart';
import '../models/lab_title_request.dart';

class LabsTitlesRepository extends BaseApiService {
  const LabsTitlesRepository() : super(UserRole.admin);

  /// GET /labs-titles
  Future<List<LabTitleModel>> fetchLabsTitles() async {
    try {
      final data = await get<Map<String, dynamic>>(
        ApiConstants.labsTitles,
        cancelTag: 'labs_titles_list',
      );
      final list = data['data'] as List<dynamic>;
      return list
          .map((e) => LabTitleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on NetworkException {
      rethrow;
    }
  }

  /// POST /labs-titles
  Future<LabTitleModel> createLabTitle(LabTitleRequest request) async {
    try {
      final data = await post<Map<String, dynamic>>(
        ApiConstants.labsTitles,
        data: request.toJson(),
        cancelTag: 'labs_titles_create',
      );
      return LabTitleModel.fromJson(data['data'] as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    }
  }

  /// PUT /labs-titles/{id}
  Future<LabTitleModel> updateLabTitle(
      int id, LabTitleRequest request) async {
    try {
      final data = await put<Map<String, dynamic>>(
        ApiConstants.labTitleById(id),
        data: request.toJson(),
        cancelTag: 'labs_titles_update_$id',
      );
      return LabTitleModel.fromJson(data['data'] as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    }
  }

  /// DELETE /labs-titles/{id}
  Future<void> deleteLabTitle(int id) async {
    try {
      await delete<dynamic>(
        ApiConstants.labTitleById(id),
        cancelTag: 'labs_titles_delete_$id',
      );
    } on NetworkException {
      rethrow;
    }
  }
}

