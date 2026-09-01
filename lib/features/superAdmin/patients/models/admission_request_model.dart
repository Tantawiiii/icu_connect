import 'dart:io';

import 'package:dio/dio.dart';

/// Draft row for POST /admissions or nested arrays on PUT.
class AdmissionClinicalNoteDraft {
  const AdmissionClinicalNoteDraft({required this.type, required this.content});

  final String type;
  final String content;

  Map<String, dynamic> toJson() => {'type': type, 'content': content};
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
    required this.drugId,
    required this.dose,
    required this.frequency,
    this.doseUnitId,
    this.type,
    this.isDiscontinued = false,
  });

  final int drugId;
  final String dose;
  final String frequency;
  final int? doseUnitId;
  final String? type;
  final bool isDiscontinued;

  Map<String, dynamic> toJson() => {
    'drug_id': drugId,
    'dose': dose,
    if (doseUnitId != null) 'dose_unit_id': doseUnitId,
    'frequency': frequency,
    if (type != null && type!.trim().isNotEmpty) 'type': type,
    'is_discontinued': isDiscontinued,
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

class AdmissionCultureAntibioticDraft {
  const AdmissionCultureAntibioticDraft({
    this.id,
    this.drugId,
    this.drugName,
    required this.sensitivity,
    this.delete = false,
  });

  final int? id;
  final int? drugId;
  final String? drugName;
  final String sensitivity;
  final bool delete;

  Map<String, dynamic> toJson() {
    if (delete && id != null) {
      return {'id': id, '_delete': true};
    }
    final m = <String, dynamic>{'sensitivity': sensitivity.toUpperCase()};
    if (id != null) m['id'] = id;
    if (drugId != null) {
      m['drug_id'] = drugId;
    } else {
      final name = drugName?.trim() ?? '';
      if (name.isNotEmpty) m['drug_name'] = name;
    }
    return m;
  }
}

class AdmissionCultureDraft {
  const AdmissionCultureDraft({
    required this.title,
    required this.note,
    this.antibiotics = const [],
  });

  final String title;
  final String note;
  final List<AdmissionCultureAntibioticDraft> antibiotics;

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{'title': title, 'note': note};
    if (antibiotics.isNotEmpty) {
      m['antibiotics'] = antibiotics.map((e) => e.toJson()).toList();
    }
    return m;
  }
}

class AdmissionConsultationDraft {
  const AdmissionConsultationDraft({
    this.id,
    required this.speciality,
    required this.reply,
  });

  final int? id;
  final String speciality;
  final String reply;

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{'speciality': speciality, 'reply': reply};
    if (id != null) m['id'] = id;
    return m;
  }
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
    this.consultations = const [],
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
  final List<AdmissionConsultationDraft> consultations;

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
      m['radiology_images'] = radiologyImages.map((e) => e.toJson()).toList();
    }
    if (treatmentPlans.isNotEmpty) {
      m['treatment_plans'] = treatmentPlans.map((e) => e.toJson()).toList();
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
    if (consultations.isNotEmpty) {
      m['consultations'] = consultations.map((e) => e.toJson()).toList();
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
      addField('medications[$i][drug_id]', '${med.drugId}');
      addField('medications[$i][dose]', med.dose);
      addField('medications[$i][frequency]', med.frequency);
      addField(
        'medications[$i][is_discontinued]',
        med.isDiscontinued ? '1' : '0',
      );
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
      for (var j = 0; j < c.antibiotics.length; j++) {
        final a = c.antibiotics[j];
        if (a.delete && a.id != null) {
          addField('cultures[$i][antibiotics][$j][id]', '${a.id}');
          addField('cultures[$i][antibiotics][$j][_delete]', '1');
          continue;
        }
        if (a.id != null) {
          addField('cultures[$i][antibiotics][$j][id]', '${a.id}');
        }
        if (a.drugId != null) {
          addField('cultures[$i][antibiotics][$j][drug_id]', '${a.drugId}');
        } else {
          final name = a.drugName?.trim() ?? '';
          if (name.isNotEmpty) {
            addField('cultures[$i][antibiotics][$j][drug_name]', name);
          }
        }
        addField(
          'cultures[$i][antibiotics][$j][sensitivity]',
          a.sensitivity.toUpperCase(),
        );
      }
    }

    for (var i = 0; i < consultations.length; i++) {
      final c = consultations[i];
      if (c.id != null) addField('consultations[$i][id]', '${c.id}');
      addField('consultations[$i][speciality]', c.speciality);
      addField('consultations[$i][reply]', c.reply);
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
    this.consultations = const [],
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
  final List<AdmissionConsultationDraft> consultations;

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
      cultures.isEmpty &&
      consultations.isEmpty;

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
      m['radiology_images'] = radiologyImages.map((e) => e.toJson()).toList();
    }
    if (treatmentPlans.isNotEmpty) {
      m['treatment_plans'] = treatmentPlans.map((e) => e.toJson()).toList();
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
    if (consultations.isNotEmpty) {
      m['consultations'] = consultations.map((e) => e.toJson()).toList();
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
      addField('medications[$i][drug_id]', '${med.drugId}');
      addField('medications[$i][dose]', med.dose);
      addField('medications[$i][frequency]', med.frequency);
      addField(
        'medications[$i][is_discontinued]',
        med.isDiscontinued ? '1' : '0',
      );
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
      for (var j = 0; j < c.antibiotics.length; j++) {
        final a = c.antibiotics[j];
        if (a.delete && a.id != null) {
          addField('cultures[$i][antibiotics][$j][id]', '${a.id}');
          addField('cultures[$i][antibiotics][$j][_delete]', '1');
          continue;
        }
        if (a.id != null) {
          addField('cultures[$i][antibiotics][$j][id]', '${a.id}');
        }
        if (a.drugId != null) {
          addField('cultures[$i][antibiotics][$j][drug_id]', '${a.drugId}');
        } else {
          final name = a.drugName?.trim() ?? '';
          if (name.isNotEmpty) {
            addField('cultures[$i][antibiotics][$j][drug_name]', name);
          }
        }
        addField(
          'cultures[$i][antibiotics][$j][sensitivity]',
          a.sensitivity.toUpperCase(),
        );
      }
    }

    for (var i = 0; i < consultations.length; i++) {
      final c = consultations[i];
      if (c.id != null) addField('consultations[$i][id]', '${c.id}');
      addField('consultations[$i][speciality]', c.speciality);
      addField('consultations[$i][reply]', c.reply);
    }

    return fd;
  }
}

String _numStr(double v) {
  if (v == v.roundToDouble()) return '${v.toInt()}';
  return '$v';
}
