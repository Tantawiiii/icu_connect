import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';

String admissionDetailsFormatDate(String? raw) {
  if (raw == null || raw.isEmpty) return AppTexts.notAvailable;
  final t = raw.indexOf('T');
  return t > 0 ? raw.substring(0, t) : raw;
}

String admissionDetailsFormatDateTime(String raw) {
  if (raw.isEmpty) return AppTexts.notAvailable;
  final t = raw.indexOf('T');
  if (t <= 0) return raw;
  final date = raw.substring(0, t);
  final time = raw.length > t + 1
      ? raw.substring(t + 1, raw.length > t + 9 ? t + 9 : raw.length)
      : '';
  return time.isEmpty ? date : '$date $time';
}

String admissionDetailsSqlDateTime(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')} '
    '${d.hour.toString().padLeft(2, '0')}:'
    '${d.minute.toString().padLeft(2, '0')}:'
    '${d.second.toString().padLeft(2, '0')}';

Color admissionDetailsStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'admitted':
      return AppColors.success;
    case 'discharged':
      return Colors.orange;
    case 'deceased':
      return AppColors.error;
    default:
      return AppColors.textSecondary;
  }
}
