import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';

import '../enums/admission_status.dart';

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

String admissionStatusDisplayLabel(String? status) =>
    AdmissionStatus.displayLabelFor(status);

Color admissionDetailsStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'admitted':
    case 'active':
      return AppColors.success;
    case 'discharged':
      return const Color(0xFF2E7D32);
    case 'leaves_ama':
      return Colors.deepOrange;
    case 'deceased':
      return AppColors.error;
    case 'referred':
      return AppColors.accent;
    case 'inactive':
      return AppColors.textSecondary;
    default:
      return AppColors.textSecondary;
  }
}
