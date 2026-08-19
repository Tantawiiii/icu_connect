import 'package:icu_connect/core/constants/app_texts.dart';

import '../models/admission_activity.dart';
import '../widgets/admission_details_formatters.dart';

String admissionActivityFieldLabel(String field) {
  switch (field) {
    case 'status':
      return 'status';
    case 'bed_number':
      return 'bed';
    case 'notes':
      return 'notes';
    case 'name':
      return 'name';
    case 'national_id':
      return 'national ID';
    case 'age':
      return 'age';
    case 'gender':
      return 'gender';
    case 'blood_group':
      return 'blood group';
    case 'phone':
      return 'phone';
    case 'date_comes':
      return 'admission date';
    case 'date_leave':
      return 'discharge date';
    case 'date_of_death':
      return 'date of death';
    case 'content':
      return 'content';
    case 'plan_content':
      return 'plan';
    case 'value':
      return 'value';
    case 'title':
      return 'title';
    case 'type':
      return 'type';
    case 'duration':
      return 'duration';
    case 'report':
      return 'report';
    case 'text':
      return 'text';
    case 'note':
      return 'note';
    default:
      return field.replaceAll('_', ' ');
  }
}

String admissionActivityFormatValue(String field, String? raw) {
  if (raw == null || raw.trim().isEmpty) return AppTexts.notAvailable;
  if (field == 'status') return admissionStatusDisplayLabel(raw);
  return raw.trim();
}

String admissionActivitySubjectLabel(AdmissionActivity activity) {
  return activity.subjectTypeEnum?.label ??
      (activity.subjectType.isEmpty
          ? AppTexts.activityHistorySection
          : activity.subjectType.replaceAll('_', ' '));
}

String admissionActivityEventLabel(AdmissionActivity activity) {
  final event = activity.event.trim().toLowerCase();
  if (event.isEmpty) return '';
  return event[0].toUpperCase() + event.substring(1);
}

String admissionActivityActorName(AdmissionActivity activity) {
  final name = activity.actorName?.trim();
  if (name != null && name.isNotEmpty) return name;
  return 'User';
}

List<String> admissionActivityChangeLines(AdmissionActivity activity) {
  if (activity.changes.isNotEmpty) {
    final actor = admissionActivityActorName(activity);
    return activity.changes.map((change) {
      final field = admissionActivityFieldLabel(change.field);
      final oldValue = admissionActivityFormatValue(
        change.field,
        change.oldValue,
      );
      final newValue = admissionActivityFormatValue(
        change.field,
        change.newValue,
      );

      final hasOld =
          change.oldValue != null && change.oldValue!.trim().isNotEmpty;
      final hasNew =
          change.newValue != null && change.newValue!.trim().isNotEmpty;

      if (hasOld && hasNew) {
        return '$actor changed $field from $oldValue to $newValue';
      }
      if (hasNew) {
        return '$actor set $field to $newValue';
      }
      if (hasOld) {
        return '$actor cleared $field (was $oldValue)';
      }
      return '$actor updated $field';
    }).toList();
  }

  final actor = admissionActivityActorName(activity);
  final subject = admissionActivitySubjectLabel(activity);
  final event = activity.event.trim().toLowerCase();

  if (event == 'created' || event == 'added') {
    return ['$actor added $subject'];
  }
  if (event == 'deleted' || event == 'removed') {
    return ['$actor deleted $subject'];
  }
  if (event == 'updated' || event == 'changed') {
    if (activity.description.isNotEmpty) {
      return ['$actor updated $subject: ${activity.description}'];
    }
    return ['$actor updated $subject'];
  }
  if (activity.description.isNotEmpty) {
    return [activity.description];
  }
  return [];
}

String admissionActivityTitle(AdmissionActivity activity) {
  final subject = admissionActivitySubjectLabel(activity);
  final event = admissionActivityEventLabel(activity);
  if (event.isEmpty) return subject;
  return '$subject · $event';
}
