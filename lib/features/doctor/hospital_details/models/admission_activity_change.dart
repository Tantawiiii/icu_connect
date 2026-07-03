import 'package:equatable/equatable.dart';

class AdmissionActivityChange extends Equatable {
  const AdmissionActivityChange({
    required this.field,
    this.oldValue,
    this.newValue,
  });

  final String field;
  final String? oldValue;
  final String? newValue;

  @override
  List<Object?> get props => [field, oldValue, newValue];
}

String? _activityValueToString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value.trim().isEmpty ? null : value.trim();
  if (value is num || value is bool) return value.toString();
  return value.toString();
}

List<AdmissionActivityChange> parseAdmissionActivityChanges(
  Map<String, dynamic> json,
) {
  final changes = <AdmissionActivityChange>[];
  final seen = <String>{};

  void addChange(String field, dynamic oldRaw, dynamic newRaw) {
    if (field.isEmpty || seen.contains(field)) return;
    final oldValue = _activityValueToString(oldRaw);
    final newValue = _activityValueToString(newRaw);
    if (oldValue == newValue) return;
    seen.add(field);
    changes.add(
      AdmissionActivityChange(
        field: field,
        oldValue: oldValue,
        newValue: newValue,
      ),
    );
  }

  final changesMap = json['changes'];
  if (changesMap is Map<String, dynamic>) {
    for (final entry in changesMap.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        addChange(
          entry.key,
          value['old'] ?? value['from'] ?? value['previous'],
          value['new'] ?? value['to'] ?? value['current'],
        );
      } else {
        addChange(entry.key, null, value);
      }
    }
  }

  Map<String, dynamic>? oldMap;
  Map<String, dynamic>? newMap;

  final oldValues = json['old_values'] ?? json['old'];
  if (oldValues is Map<String, dynamic>) oldMap = oldValues;

  final newValues =
      json['new_values'] ?? json['new'] ?? json['attributes'] ?? json['after'];
  if (newValues is Map<String, dynamic>) newMap = newValues;

  final properties = json['properties'];
  if (properties is Map<String, dynamic>) {
    oldMap ??= properties['old'] is Map<String, dynamic>
        ? properties['old'] as Map<String, dynamic>
        : null;
    newMap ??= properties['attributes'] is Map<String, dynamic>
        ? properties['attributes'] as Map<String, dynamic>
        : properties['new'] is Map<String, dynamic>
            ? properties['new'] as Map<String, dynamic>
            : null;
  }

  if (oldMap != null || newMap != null) {
    final keys = <String>{
      ...?oldMap?.keys.map((e) => e.toString()),
      ...?newMap?.keys.map((e) => e.toString()),
    };
    for (final key in keys) {
      addChange(key, oldMap?[key], newMap?[key]);
    }
  }

  return changes;
}
