enum AdmissionActivitySubjectType {
  admission('admission'),
  patient('patient'),
  clinicalNote('clinical_note'),
  radiologyImage('radiology_image'),
  treatmentPlan('treatment_plan'),
  vital('vital'),
  lab('lab'),
  medication('medication'),
  echo('echo'),
  ultrasound('ultrasound'),
  culture('culture');

  const AdmissionActivitySubjectType(this.apiValue);

  final String apiValue;

  String get label {
    switch (this) {
      case AdmissionActivitySubjectType.admission:
        return 'Admission';
      case AdmissionActivitySubjectType.patient:
        return 'Patient';
      case AdmissionActivitySubjectType.clinicalNote:
        return 'Clinical note';
      case AdmissionActivitySubjectType.radiologyImage:
        return 'Radiology';
      case AdmissionActivitySubjectType.treatmentPlan:
        return 'Treatment plan';
      case AdmissionActivitySubjectType.vital:
        return 'Vital';
      case AdmissionActivitySubjectType.lab:
        return 'Lab';
      case AdmissionActivitySubjectType.medication:
        return 'Medication';
      case AdmissionActivitySubjectType.echo:
        return 'Echo';
      case AdmissionActivitySubjectType.ultrasound:
        return 'Ultrasound';
      case AdmissionActivitySubjectType.culture:
        return 'Culture';
    }
  }

  static AdmissionActivitySubjectType? fromApiValue(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final normalized = raw.toLowerCase().trim();
    for (final type in values) {
      if (type.apiValue == normalized) return type;
    }
    return null;
  }
}
