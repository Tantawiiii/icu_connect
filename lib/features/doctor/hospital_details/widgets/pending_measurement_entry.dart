import 'package:flutter/material.dart';

/// Inline vital/lab row being added from admission details.
class PendingMeasurementEntry {
  PendingMeasurementEntry()
      : valueCtrl = TextEditingController(),
        date = DateTime.now();
  int? titleId;
  final TextEditingController valueCtrl;
  DateTime date;
}
