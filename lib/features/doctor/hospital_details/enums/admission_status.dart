import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:flutter/material.dart';

/// Admission status values accepted by the hospital API.
enum AdmissionStatus {
  active('active', 'Active'),
  inactive('inactive', 'Inactive'),
  admitted('admitted', 'Admitted'),
  discharged('discharged', 'Improved'),
  leavesAma('leaves_ama', 'DAMA'),
  deceased('deceased', 'Die'),
  referred('referred', 'Referred');

  const AdmissionStatus(this.apiValue, this.displayLabel);

  final String apiValue;

  /// User-facing label (independent from [apiValue] sent to the backend).
  final String displayLabel;

  @Deprecated('Use displayLabel')
  String get label => displayLabel;

  static AdmissionStatus fromApiValue(String? raw) {
    final normalized = (raw ?? '').toLowerCase().trim();
    for (final status in AdmissionStatus.values) {
      if (status.apiValue == normalized) return status;
    }
    return AdmissionStatus.admitted;
  }

  static String displayLabelFor(String? raw) {
    if (raw == null || raw.trim().isEmpty) return AppTexts.notAvailable;
    return fromApiValue(raw).displayLabel;
  }

  /// Statuses doctors can pick when editing an admission.
  static List<AdmissionStatus> get editable => const [
    AdmissionStatus.admitted,
    AdmissionStatus.discharged,
    AdmissionStatus.leavesAma,
    AdmissionStatus.deceased,
    AdmissionStatus.referred,
  ];

  /// Chips on the hospital admissions list (API filters by exact status).
  static List<AdmissionStatus> get listFilters => const [
    AdmissionStatus.admitted,
    AdmissionStatus.discharged,
    AdmissionStatus.leavesAma,
    AdmissionStatus.deceased,
    AdmissionStatus.referred,
  ];

  /// Outcomes shown on the discharged patients dashboard.
  static List<AdmissionStatus> get dischargedOutcomes => const [
    AdmissionStatus.discharged,
    AdmissionStatus.deceased,
    AdmissionStatus.leavesAma,
  ];

  static bool isDischargedOutcome(String? raw) {
    final status = fromApiValue(raw);
    return dischargedOutcomes.contains(status);
  }

  /// Label used on the discharged patients screen chips/list.
  String get dischargedScreenLabel {
    switch (this) {
      case AdmissionStatus.discharged:
        return 'Improved';
      case AdmissionStatus.deceased:
        return 'Die';
      case AdmissionStatus.leavesAma:
        return 'DAMA';
      default:
        return displayLabel;
    }
  }

  Color get dischargedOutcomeBackground {
    switch (this) {
      case AdmissionStatus.discharged:
        return const Color(0xFFD1E7DD);
      case AdmissionStatus.deceased:
        return const Color(0xFFF8D7DA);
      case AdmissionStatus.leavesAma:
        return const Color(0xFFD1D2F9);
      default:
        return const Color(0xFFF5F6FA);
    }
  }

  bool get requiresLeaveDate =>
      this == discharged || this == leavesAma || this == referred;

  bool get requiresDeathDate => this == deceased;

  bool get occupiesBed => this == admitted || this == active;
}

class AdmissionClinicalNoteType {
  AdmissionClinicalNoteType._();

  static const historyComplaint = 'history_complaint';
  static const progressNote = 'progress_note';

  static const values = <String>[historyComplaint, progressNote];

  static const labels = <String, String>{
    historyComplaint: 'History & complaint',
    progressNote: 'Progress note',
  };

  static String labelFor(String type) =>
      labels[type] ?? type.replaceAll('_', ' ');

  static String normalize(String? raw) {
    final value = (raw ?? '').trim();
    if (values.contains(value)) return value;
    return progressNote;
  }
}
