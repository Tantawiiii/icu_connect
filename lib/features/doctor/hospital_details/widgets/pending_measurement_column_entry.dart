import 'package:flutter/material.dart';

import 'package:icu_connect/features/superAdmin/patients/models/patient_admission_models.dart';

/// Batch vital/lab column entry — one date, values for all titles.
class PendingMeasurementColumnEntry {
  PendingMeasurementColumnEntry({
    required List<MeasurementTitleModel> titles,
    DateTime? date,
    Map<int, int>? recordIdsByTitleId,
    Map<int, String>? initialValuesByTitleId,
    this.editingColumnKey,
  })  : date = date ?? DateTime.now(),
        recordIdsByTitleId = Map<int, int>.from(recordIdsByTitleId ?? {}),
        controllers = {
          for (final t in titles)
            t.id: TextEditingController(
              text: initialValuesByTitleId?[t.id] ?? '',
            ),
        };

  DateTime date;
  final Map<int, int> recordIdsByTitleId;
  final Map<int, TextEditingController> controllers;

  /// When set, the edit UI replaces this date column in-place.
  final String? editingColumnKey;

  bool get isEditingExisting => recordIdsByTitleId.isNotEmpty;
  bool get isNewColumn => editingColumnKey == null;

  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
  }
}
