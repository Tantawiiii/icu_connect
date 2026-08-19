import 'package:icu_connect/core/constants/app_texts.dart';

import '../enums/admission_status.dart';

class AdmissionUpdateValidation {
  AdmissionUpdateValidation._();

  static const int maxBedNumberLength = 50;
  static const int maxRadiologyTitleLength = 255;

  static String? bedNumber(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return 'Bed number is required';
    if (value.length > maxBedNumberLength) {
      return 'Bed number must be at most $maxBedNumberLength characters';
    }
    return null;
  }

  static String? admissionStatusDates({
    required AdmissionStatus status,
    DateTime? dateComes,
    DateTime? dateLeave,
    DateTime? dateOfDeath,
  }) {
    if (status.requiresLeaveDate && dateLeave == null) {
      return 'Set a leave date for ${status.displayLabel} status';
    }
    if (status.requiresDeathDate && dateOfDeath == null) {
      return 'Set date of death for ${status.displayLabel} status';
    }
    if (dateComes != null &&
        dateLeave != null &&
        dateLeave.isBefore(dateComes)) {
      return AppTexts.admissionLeaveNotBeforeComes;
    }
    if (dateComes != null &&
        dateOfDeath != null &&
        dateOfDeath.isBefore(dateComes)) {
      return AppTexts.admissionDeathNotBeforeComes;
    }
    return null;
  }

  static String? clinicalNoteContent(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return 'Note content is required';
    return null;
  }

  static String? treatmentPlanContent(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return 'Plan content is required';
    return null;
  }

  static String? radiologyTitle(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return 'Title is required';
    if (value.length > maxRadiologyTitleLength) {
      return 'Title must be at most $maxRadiologyTitleLength characters';
    }
    return null;
  }

  static String? requiredText(String? raw, {required String field}) {
    if ((raw?.trim() ?? '').isEmpty) return '$field is required';
    return null;
  }

  static String? measurementValue({
    required String? raw,
    required String field,
    required bool isNumeric,
  }) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return '$field is required';
    if (isNumeric && double.tryParse(value) == null) {
      return '$field must be a number';
    }
    return null;
  }

  static String? numericValue(String? raw, {required String field}) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return '$field is required';
    if (double.tryParse(value) == null) {
      return '$field must be a number';
    }
    return null;
  }

  static String? medicationFields({
    required int? drugId,
    required String dose,
    required String frequency,
  }) {
    if (drugId == null) {
      return 'Select a drug from the formulary';
    }
    final doseError = requiredText(dose, field: 'Dose');
    if (doseError != null) return doseError;
    return requiredText(frequency, field: 'Frequency');
  }
}
