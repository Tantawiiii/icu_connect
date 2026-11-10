import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';

import '../../../../core/utils/date_formatters.dart' as date_formatters;
import '../enums/admission_status.dart';

String admissionDetailsFormatDate(String? raw) =>
    date_formatters.isoDateOnly(raw);

String admissionDetailsFormatDateTime(String raw) =>
    date_formatters.isoDateTime(raw);

String admissionDetailsSqlDateTime(DateTime d) =>
    date_formatters.toSqlDateTime(d);

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
