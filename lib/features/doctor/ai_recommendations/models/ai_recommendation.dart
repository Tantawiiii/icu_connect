import 'package:equatable/equatable.dart';

enum AiConfidence {
  low,
  medium,
  high,
  unknown;

  static AiConfidence fromApi(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'low':
        return AiConfidence.low;
      case 'medium':
        return AiConfidence.medium;
      case 'high':
        return AiConfidence.high;
      default:
        return AiConfidence.unknown;
    }
  }

  String get label => switch (this) {
        AiConfidence.low => 'Low',
        AiConfidence.medium => 'Medium',
        AiConfidence.high => 'High',
        AiConfidence.unknown => '—',
      };
}

class AiRecommendation extends Equatable {
  const AiRecommendation({
    required this.summary,
    required this.priorityConcerns,
    required this.recommendations,
    required this.missingData,
    required this.safetyFlags,
    required this.confidence,
  });

  final String summary;
  final List<String> priorityConcerns;
  final List<String> recommendations;
  final List<String> missingData;
  final List<String> safetyFlags;
  final AiConfidence confidence;

  factory AiRecommendation.fromJson(Map<String, dynamic> json) {
    List<String> list(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return AiRecommendation(
      summary: json['summary']?.toString() ?? '',
      priorityConcerns: list(json['priority_concerns']),
      recommendations: list(json['recommendations']),
      missingData: list(json['missing_data']),
      safetyFlags: list(json['safety_flags']),
      confidence: AiConfidence.fromApi(json['confidence']?.toString()),
    );
  }

  @override
  List<Object?> get props => [
        summary,
        priorityConcerns,
        recommendations,
        missingData,
        safetyFlags,
        confidence,
      ];
}

class AiRecommendationRawMeta extends Equatable {
  const AiRecommendationRawMeta({
    this.finishReason,
    this.promptTokens,
    this.completionTokens,
  });

  final String? finishReason;
  final int? promptTokens;
  final int? completionTokens;

  factory AiRecommendationRawMeta.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AiRecommendationRawMeta();
    return AiRecommendationRawMeta(
      finishReason: json['finishReason']?.toString() ??
          json['finish_reason']?.toString(),
      promptTokens: (json['promptTokens'] as num?)?.toInt() ??
          (json['prompt_tokens'] as num?)?.toInt(),
      completionTokens: (json['completionTokens'] as num?)?.toInt() ??
          (json['completion_tokens'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props => [finishReason, promptTokens, completionTokens];
}

class AiRecommendationResult extends Equatable {
  const AiRecommendationResult({
    required this.recommendation,
    required this.raw,
    this.message,
  });

  final AiRecommendation recommendation;
  final AiRecommendationRawMeta raw;
  final String? message;

  factory AiRecommendationResult.fromResponse(Map<String, dynamic> root) {
    final data = root['data'];
    final map = data is Map<String, dynamic> ? data : root;
    final recRaw = map['recommendation'];
    final recMap = recRaw is Map<String, dynamic>
        ? recRaw
        : <String, dynamic>{};
    final rawMeta = map['raw'];
    return AiRecommendationResult(
      recommendation: AiRecommendation.fromJson(recMap),
      raw: AiRecommendationRawMeta.fromJson(
        rawMeta is Map<String, dynamic> ? rawMeta : null,
      ),
      message: root['message']?.toString(),
    );
  }

  @override
  List<Object?> get props => [recommendation, raw, message];
}
