import 'package:equatable/equatable.dart';

import '../enums/admission_activity_subject_type.dart';
import 'admission_activity_change.dart';

class AdmissionActivity extends Equatable {
  const AdmissionActivity({
    required this.id,
    required this.subjectType,
    this.subjectId,
    required this.event,
    required this.description,
    this.actorName,
    required this.createdAt,
    this.changes = const [],
  });

  final int id;
  final String subjectType;
  final int? subjectId;
  final String event;
  final String description;
  final String? actorName;
  final String createdAt;
  final List<AdmissionActivityChange> changes;

  AdmissionActivitySubjectType? get subjectTypeEnum =>
      AdmissionActivitySubjectType.fromApiValue(subjectType);

  factory AdmissionActivity.fromJson(Map<String, dynamic> json) {
    final actor = json['user'] ?? json['causer'] ?? json['doctor'];
    String? actorName;
    if (actor is Map<String, dynamic>) {
      actorName = actor['name'] as String?;
    }

    final description =
        [json['description'], json['message'], json['note'], json['summary']]
            .whereType<String>()
            .map((e) => e.trim())
            .firstWhere((e) => e.isNotEmpty, orElse: () => '');

    return AdmissionActivity(
      id: (json['id'] as num?)?.toInt() ?? 0,
      subjectType: json['subject_type'] as String? ?? '',
      subjectId: (json['subject_id'] as num?)?.toInt(),
      event: (json['event'] ?? json['action'] ?? json['type'] ?? '').toString(),
      description: description,
      actorName: actorName ?? json['user_name'] as String?,
      createdAt:
          json['created_at'] as String? ??
          json['performed_at'] as String? ??
          '',
      changes: parseAdmissionActivityChanges(json),
    );
  }

  @override
  List<Object?> get props => [
    id,
    subjectType,
    subjectId,
    event,
    description,
    actorName,
    createdAt,
    changes,
  ];
}
