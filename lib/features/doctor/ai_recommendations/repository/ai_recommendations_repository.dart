import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/services/base_api_service.dart';
import '../enums/ai_recommend_feature.dart';
import '../models/ai_recommendation.dart';

/// AI recommendations for an admission (Sanctum: doctor / admin / super admin).
class AiRecommendationsRepository extends BaseApiService {
  const AiRecommendationsRepository() : super(UserRole.hospital);

  /// POST `/ai/recommend/{feature}` with body:
  /// `{ admission_id, language, refresh }`.
  Future<AiRecommendationResult> recommend({
    required AiRecommendFeature feature,
    required int admissionId,
    String language = 'en',
    bool refresh = false,
  }) async {
    final body = <String, dynamic>{
      'admission_id': admissionId,
      'language': language,
      'refresh': refresh,
    };
    final options = Options(
      receiveTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
      headers: const {'Accept': 'application/json'},
    );

    try {
      return await _fetch(
        path: feature.path,
        body: body,
        options: options,
        cancelTag: 'ai_shared_${feature.apiKey}_$admissionId',
      );
    } on NetworkException catch (e) {
      if (e.statusCode != 403 && e.statusCode != 404) rethrow;
    }

    return _fetch(
      path: '/ai/recommend/${feature.apiKey}',
      body: body,
      options: options,
      cancelTag: 'ai_hospital_${feature.apiKey}_$admissionId',
    );
  }

  Future<AiRecommendationResult> _fetch({
    required String path,
    required Map<String, dynamic> body,
    required Options options,
    required String cancelTag,
  }) async {
    final data = await post<Map<String, dynamic>>(
      path,
      data: body,
      cancelTag: cancelTag,
      options: options,
    );
    return AiRecommendationResult.fromResponse(data);
  }
}
