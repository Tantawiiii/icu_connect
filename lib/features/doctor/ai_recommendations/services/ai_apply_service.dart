import '../../hospital_details/enums/admission_status.dart';
import '../../hospital_details/repository/hospital_admissions_repository.dart';
import '../enums/ai_recommend_feature.dart';

/// Where a selected AI suggestion is written on the admission chart.
enum AiApplyTarget {
  timelineNote,
  progressNote,
  treatmentPlan;

  String get label => switch (this) {
        AiApplyTarget.timelineNote => 'Clinical Timeline',
        AiApplyTarget.progressNote => 'Progress note',
        AiApplyTarget.treatmentPlan => 'Treatment plan',
      };

  String get hint => switch (this) {
        AiApplyTarget.timelineNote =>
          'Adds a team timeline note with the selected items.',
        AiApplyTarget.progressNote =>
          'Adds a progress clinical note on the admission.',
        AiApplyTarget.treatmentPlan =>
          'Creates treatment-plan entries from each selected item.',
      };
}

class AiApplyService {
  AiApplyService({HospitalAdmissionsRepository? admissionsRepository})
      : _admissions =
            admissionsRepository ?? const HospitalAdmissionsRepository();

  final HospitalAdmissionsRepository _admissions;

  /// Smart default destination based on the AI feature being reviewed.
  static AiApplyTarget defaultTargetFor(AiRecommendFeature feature) {
    return switch (feature) {
      AiRecommendFeature.treatmentPlan => AiApplyTarget.treatmentPlan,
      AiRecommendFeature.progressNotes ||
      AiRecommendFeature.diagnosis ||
      AiRecommendFeature.discharge =>
        AiApplyTarget.progressNote,
      _ => AiApplyTarget.timelineNote,
    };
  }

  Future<void> apply({
    required int admissionId,
    required AiRecommendFeature feature,
    required AiApplyTarget target,
    required List<String> items,
  }) async {
    final cleaned = items
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return;

    final header = 'AI · ${feature.label} — applied suggestions:';

    switch (target) {
      case AiApplyTarget.timelineNote:
        final buffer = StringBuffer()
          ..writeln(header)
          ..writeln();
        for (var i = 0; i < cleaned.length; i++) {
          buffer.writeln('${i + 1}. ${cleaned[i]}');
        }
        await _admissions.createAdmissionNote(
          admissionId,
          content: buffer.toString().trim(),
        );
      case AiApplyTarget.progressNote:
        final buffer = StringBuffer()
          ..writeln(header)
          ..writeln();
        for (var i = 0; i < cleaned.length; i++) {
          buffer.writeln('${i + 1}. ${cleaned[i]}');
        }
        await _admissions.updateAdmissionRaw(admissionId, {
          'clinical_notes': [
            {
              'type': AdmissionClinicalNoteType.progressNote,
              'content': buffer.toString().trim(),
            },
          ],
        });
      case AiApplyTarget.treatmentPlan:
        await _admissions.updateAdmissionRaw(admissionId, {
          'treatment_plans': [
            for (final item in cleaned) {'plan_content': item},
          ],
        });
    }
  }
}
