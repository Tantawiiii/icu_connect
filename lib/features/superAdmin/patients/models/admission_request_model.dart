import 'dart:io';

import 'package:dio/dio.dart';

/// Draft row for POST /admissions or nested arrays on PUT.
class AdmissionClinicalNoteDraft {
  const AdmissionClinicalNoteDraft({
    required this.type,
    required this.content,
  });

  final String type;
  final String content;

  Map<String, dynamic> toJson() => {
        'type': type,
        'content': content,
      };
}

class AdmissionRadiologyDraft {
  const AdmissionRadiologyDraft({
    required this.title,
    this.report,
    this.imagePath,
    this.localImagePath,
  });

  final String title;
  final String? report;
  final String? imagePath;
  final String? localImagePath;

  bool get hasFile =>
      localImagePath != null && localImagePath!.trim().isNotEmpty;

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{'title': title};
    if (report != null && report!.isNotEmpty) m['report'] = report;
    if (imagePath != null && imagePath!.isNotEmpty) m['image_path'] = imagePath;
    return m;
  }
}

class AdmissionTreatmentDraft {
  const AdmissionTreatmentDraft({required this.planContent});

  final String planContent;

  Map<String, dynamic> toJson() => {'plan_content': planContent};
}

class AdmissionVitalDraft {
  const AdmissionVitalDraft({
    required this.vitalsTitleId,
    required this.value,
    required this.date,
  });

  final int vitalsTitleId;
  final double value;
  final String date;

  Map<String, dynamic> toJson() => {
        'vitals_title_id': vitalsTitleId,
        'value': value,
        'date': date,
      };
}

class AdmissionLabDraft {
  const AdmissionLabDraft({
    required this.labsTitleId,
    required this.value,
    required this.date,
  });

  final int labsTitleId;
  final double value;
  final String date;

  Map<String, dynamic> toJson() => {
        'labs_title_id': labsTitleId,
        'value': value,
        'date': date,
      };
}

class AdmissionMedicationDraft {
  const AdmissionMedicationDraft({
    required this.type,
    required this.title,
    required this.value,
    required this.duration,
  });

  final String type;
  final String title;
  final String value;
  final String duration;

  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'value': value,
        'duration': duration,
      };
}

class AdmissionEchoDraft {
  const AdmissionEchoDraft({required this.text});

  final String text;

  Map<String, dynamic> toJson() => {'text': text};
}

class AdmissionUltrasoundDraft {
  const AdmissionUltrasoundDraft({required this.text});

  final String text;

  Map<String, dynamic> toJson() => {'text': text};
}

class AdmissionCultureDraft {
  const AdmissionCultureDraft({
    required this.title,
    required this.note,
  });

  final String title;
  final String note;

  Map<String, dynamic> toJson() => {
        'title': title,
        'note': note,
      };
}

class AdmissionCreateRequest {
  const AdmissionCreateRequest({
    required this.patientId,
    required this.hospitalId,
    required this.doctorId,
    required this.bedNumber,
    required this.dateComes,
    this.hospitalGroupId,
    this.status,
    this.dateLeave,
    this.dateOfDeath,
    this.notes,
    this.clinicalNotes = const [],
    this.radiologyImages = const [],
    this.treatmentPlans = const [],
    this.vitals = const [],
    this.labs = const [],
    this.medications = const [],
    this.echoes = const [],
    this.ultrasounds = const [],
    this.cultures = const [],
  });

  final int patientId;
  final int hospitalId;
  final int doctorId;
  final String bedNumber;
  final String dateComes;
  final int? hospitalGroupId;
  final String? status;
  final String? dateLeave;
  final String? dateOfDeath;
  final String? notes;
  final List<AdmissionClinicalNoteDraft> clinicalNotes;
  final List<AdmissionRadiologyDraft> radiologyImages;
  final List<AdmissionTreatmentDraft> treatmentPlans;
  final List<AdmissionVitalDraft> vitals;
  final List<AdmissionLabDraft> labs;
  final List<AdmissionMedicationDraft> medications;
  final List<AdmissionEchoDraft> echoes;
  final List<AdmissionUltrasoundDraft> ultrasounds;
  final List<AdmissionCultureDraft> cultures;

  bool get needsMultipart => radiologyImages.any((r) => r.hasFile);

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'patient_id': patientId,
      'hospital_id': hospitalId,
      'doctor_id': doctorId,
      'bed_number': bedNumber,
      'date_comes': dateComes,
    };
    if (hospitalGroupId != null) m['hospital_group_id'] = hospitalGroupId;
    if (status != null && status!.isNotEmpty) m['status'] = status;
    if (dateLeave != null && dateLeave!.isNotEmpty) {
      m['date_leave'] = dateLeave;
    }
    if (dateOfDeath != null && dateOfDeath!.isNotEmpty) {
      m['date_of_death'] = dateOfDeath;
    }
    if (notes != null && notes!.isNotEmpty) m['notes'] = notes;
    if (clinicalNotes.isNotEmpty) {
      m['clinical_notes'] = clinicalNotes.map((e) => e.toJson()).toList();
    }
    if (radiologyImages.isNotEmpty) {
      m['radiology_images'] =
          radiologyImages.map((e) => e.toJson()).toList();
    }
    if (treatmentPlans.isNotEmpty) {
      m['treatment_plans'] =
          treatmentPlans.map((e) => e.toJson()).toList();
    }
    if (vitals.isNotEmpty) {
      m['vitals'] = vitals.map((e) => e.toJson()).toList();
    }
    if (labs.isNotEmpty) {
      m['labs'] = labs.map((e) => e.toJson()).toList();
    }
    if (medications.isNotEmpty) {
      m['medications'] = medications.map((e) => e.toJson()).toList();
    }
    if (echoes.isNotEmpty) {
      m['echoes'] = echoes.map((e) => e.toJson()).toList();
    }
    if (ultrasounds.isNotEmpty) {
      m['ultrasounds'] = ultrasounds.map((e) => e.toJson()).toList();
    }
    if (cultures.isNotEmpty) {
      m['cultures'] = cultures.map((e) => e.toJson()).toList();
    }
    return m;
  }

  Future<FormData> toFormData() async {
    final fd = FormData();

    void addField(String key, String value) {
      fd.fields.add(MapEntry(key, value));
    }

    addField('patient_id', '$patientId');
    addField('hospital_id', '$hospitalId');
    addField('doctor_id', '$doctorId');
    addField('bed_number', bedNumber);
    addField('date_comes', dateComes);
    if (hospitalGroupId != null) {
      addField('hospital_group_id', '$hospitalGroupId');
    }
    if (status != null && status!.isNotEmpty) addField('status', status!);
    if (dateLeave != null && dateLeave!.isNotEmpty) {
      addField('date_leave', dateLeave!);
    }
    if (dateOfDeath != null && dateOfDeath!.isNotEmpty) {
      addField('date_of_death', dateOfDeath!);
    }
    if (notes != null && notes!.isNotEmpty) addField('notes', notes!);

    for (var i = 0; i < clinicalNotes.length; i++) {
      final n = clinicalNotes[i];
      addField('clinical_notes[$i][type]', n.type);
      addField('clinical_notes[$i][content]', n.content);
    }

    for (var i = 0; i < radiologyImages.length; i++) {
      final r = radiologyImages[i];
      addField('radiology_images[$i][title]', r.title);
      if (r.report != null && r.report!.isNotEmpty) {
        addField('radiology_images[$i][report]', r.report!);
      }
      if (r.imagePath != null && r.imagePath!.isNotEmpty) {
        addField('radiology_images[$i][image_path]', r.imagePath!);
      }
      if (r.hasFile) {
        final path = r.localImagePath!.trim();
        final name = path.split(Platform.pathSeparator).last;
        fd.files.add(
          MapEntry(
            'radiology_images[$i][image]',
            await MultipartFile.fromFile(path, filename: name),
          ),
        );
      }
    }

    for (var i = 0; i < treatmentPlans.length; i++) {
      addField(
        'treatment_plans[$i][plan_content]',
        treatmentPlans[i].planContent,
      );
    }

    for (var i = 0; i < vitals.length; i++) {
      final v = vitals[i];
      addField('vitals[$i][vitals_title_id]', '${v.vitalsTitleId}');
      addField('vitals[$i][value]', _numStr(v.value));
      addField('vitals[$i][date]', v.date);
    }

    for (var i = 0; i < labs.length; i++) {
      final l = labs[i];
      addField('labs[$i][labs_title_id]', '${l.labsTitleId}');
      addField('labs[$i][value]', _numStr(l.value));
      addField('labs[$i][date]', l.date);
    }

    for (var i = 0; i < medications.length; i++) {
      final med = medications[i];
      addField('medications[$i][type]', med.type);
      addField('medications[$i][title]', med.title);
      addField('medications[$i][value]', med.value);
      addField('medications[$i][duration]', med.duration);
    }

    for (var i = 0; i < echoes.length; i++) {
      addField('echoes[$i][text]', echoes[i].text);
    }

    for (var i = 0; i < ultrasounds.length; i++) {
      addField('ultrasounds[$i][text]', ultrasounds[i].text);
    }

    for (var i = 0; i < cultures.length; i++) {
      final c = cultures[i];
      addField('cultures[$i][title]', c.title);
      addField('cultures[$i][note]', c.note);
    }

    return fd;
  }
}

class AdmissionUpdateRequest {
  const AdmissionUpdateRequest({
    this.bedNumber,
    this.hospitalGroupId,
    this.status,
    this.dateLeave,
    this.dateOfDeath,
    this.notes,
    this.clinicalNotes = const [],
    this.radiologyImages = const [],
    this.treatmentPlans = const [],
    this.vitals = const [],
    this.labs = const [],
    this.medications = const [],
    this.echoes = const [],
    this.ultrasounds = const [],
    this.cultures = const [],
  });

  final String? bedNumber;
  final int? hospitalGroupId;
  final String? status;
  final String? dateLeave;
  final String? dateOfDeath;
  final String? notes;
  final List<AdmissionClinicalNoteDraft> clinicalNotes;
  final List<AdmissionRadiologyDraft> radiologyImages;
  final List<AdmissionTreatmentDraft> treatmentPlans;
  final List<AdmissionVitalDraft> vitals;
  final List<AdmissionLabDraft> labs;
  final List<AdmissionMedicationDraft> medications;
  final List<AdmissionEchoDraft> echoes;
  final List<AdmissionUltrasoundDraft> ultrasounds;
  final List<AdmissionCultureDraft> cultures;

  bool get needsMultipart => radiologyImages.any((r) => r.hasFile);

  bool get isEmpty =>
      (bedNumber == null || bedNumber!.isEmpty) &&
      hospitalGroupId == null &&
      (status == null || status!.isEmpty) &&
      (dateLeave == null || dateLeave!.isEmpty) &&
      (dateOfDeath == null || dateOfDeath!.isEmpty) &&
      notes == null &&
      clinicalNotes.isEmpty &&
      radiologyImages.isEmpty &&
      treatmentPlans.isEmpty &&
      vitals.isEmpty &&
      labs.isEmpty &&
      medications.isEmpty &&
      echoes.isEmpty &&
      ultrasounds.isEmpty &&
      cultures.isEmpty;

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    if (bedNumber != null && bedNumber!.isNotEmpty) {
      m['bed_number'] = bedNumber;
    }
    if (hospitalGroupId != null) m['hospital_group_id'] = hospitalGroupId;
    if (status != null && status!.isNotEmpty) m['status'] = status;
    if (dateLeave != null && dateLeave!.isNotEmpty) {
      m['date_leave'] = dateLeave;
    }
    if (dateOfDeath != null && dateOfDeath!.isNotEmpty) {
      m['date_of_death'] = dateOfDeath;
    }
    if (notes != null) m['notes'] = notes;
    if (clinicalNotes.isNotEmpty) {
      m['clinical_notes'] = clinicalNotes.map((e) => e.toJson()).toList();
    }
    if (radiologyImages.isNotEmpty) {
      m['radiology_images'] =
          radiologyImages.map((e) => e.toJson()).toList();
    }
    if (treatmentPlans.isNotEmpty) {
      m['treatment_plans'] =
          treatmentPlans.map((e) => e.toJson()).toList();
    }
    if (vitals.isNotEmpty) {
      m['vitals'] = vitals.map((e) => e.toJson()).toList();
    }
    if (labs.isNotEmpty) {
      m['labs'] = labs.map((e) => e.toJson()).toList();
    }
    if (medications.isNotEmpty) {
      m['medications'] = medications.map((e) => e.toJson()).toList();
    }
    if (echoes.isNotEmpty) {
      m['echoes'] = echoes.map((e) => e.toJson()).toList();
    }
    if (ultrasounds.isNotEmpty) {
      m['ultrasounds'] = ultrasounds.map((e) => e.toJson()).toList();
    }
    if (cultures.isNotEmpty) {
      m['cultures'] = cultures.map((e) => e.toJson()).toList();
    }
    return m;
  }

  Future<FormData> toFormData() async {
    final fd = FormData();

    void addField(String key, String value) {
      fd.fields.add(MapEntry(key, value));
    }

    if (bedNumber != null && bedNumber!.isNotEmpty) {
      addField('bed_number', bedNumber!);
    }
    if (hospitalGroupId != null) {
      addField('hospital_group_id', '$hospitalGroupId');
    }
    if (status != null && status!.isNotEmpty) addField('status', status!);
    if (dateLeave != null && dateLeave!.isNotEmpty) {
      addField('date_leave', dateLeave!);
    }
    if (dateOfDeath != null && dateOfDeath!.isNotEmpty) {
      addField('date_of_death', dateOfDeath!);
    }
    if (notes != null) addField('notes', notes!);

    for (var i = 0; i < clinicalNotes.length; i++) {
      final n = clinicalNotes[i];
      addField('clinical_notes[$i][type]', n.type);
      addField('clinical_notes[$i][content]', n.content);
    }

    for (var i = 0; i < radiologyImages.length; i++) {
      final r = radiologyImages[i];
      addField('radiology_images[$i][title]', r.title);
      if (r.report != null && r.report!.isNotEmpty) {
        addField('radiology_images[$i][report]', r.report!);
      }
      if (r.imagePath != null && r.imagePath!.isNotEmpty) {
        addField('radiology_images[$i][image_path]', r.imagePath!);
      }
      if (r.hasFile) {
        final path = r.localImagePath!.trim();
        final name = path.split(Platform.pathSeparator).last;
        fd.files.add(
          MapEntry(
            'radiology_images[$i][image]',
            await MultipartFile.fromFile(path, filename: name),
          ),
        );
      }
    }

    for (var i = 0; i < treatmentPlans.length; i++) {
      addField(
        'treatment_plans[$i][plan_content]',
        treatmentPlans[i].planContent,
      );
    }

    for (var i = 0; i < vitals.length; i++) {
      final v = vitals[i];
      addField('vitals[$i][vitals_title_id]', '${v.vitalsTitleId}');
      addField('vitals[$i][value]', _numStr(v.value));
      addField('vitals[$i][date]', v.date);
    }

    for (var i = 0; i < labs.length; i++) {
      final l = labs[i];
      addField('labs[$i][labs_title_id]', '${l.labsTitleId}');
      addField('labs[$i][value]', _numStr(l.value));
      addField('labs[$i][date]', l.date);
    }

    for (var i = 0; i < medications.length; i++) {
      final med = medications[i];
      addField('medications[$i][type]', med.type);
      addField('medications[$i][title]', med.title);
      addField('medications[$i][value]', med.value);
      addField('medications[$i][duration]', med.duration);
    }

    for (var i = 0; i < echoes.length; i++) {
      addField('echoes[$i][text]', echoes[i].text);
    }

    for (var i = 0; i < ultrasounds.length; i++) {
      addField('ultrasounds[$i][text]', ultrasounds[i].text);
    }

    for (var i = 0; i < cultures.length; i++) {
      final c = cultures[i];
      addField('cultures[$i][title]', c.title);
      addField('cultures[$i][note]', c.note);
    }

    return fd;
  }
}

String _numStr(double v) {
  if (v == v.roundToDouble()) return '${v.toInt()}';
  return '$v';
}
