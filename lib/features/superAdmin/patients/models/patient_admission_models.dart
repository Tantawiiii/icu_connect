import 'package:equatable/equatable.dart';

import '../../hospitals/models/hospital_model.dart';
import '../../users/models/user_model.dart';

class AdmissionPatientModel extends Equatable {
  const AdmissionPatientModel({
    required this.id,
    required this.name,
    required this.nationalId,
    required this.age,
    required this.gender,
    required this.phone,
    required this.bloodGroup,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final int id;
  final String name;
  final String nationalId;
  final int age;
  final String gender;
  final String phone;
  final String bloodGroup;
  final String notes;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  factory AdmissionPatientModel.fromJson(Map<String, dynamic> json) =>
      AdmissionPatientModel(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        nationalId: json['national_id']?.toString() ?? '',
        age: (json['age'] as num?)?.toInt() ?? 0,
        gender: json['gender'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        bloodGroup: json['blood_group'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
        deletedAt: json['deleted_at'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    name,
    nationalId,
    age,
    gender,
    phone,
    bloodGroup,
    notes,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}

class MeasurementTitleModel extends Equatable {
  const MeasurementTitleModel({
    required this.id,
    required this.title,
    required this.unit,
    required this.normalRangeMin,
    required this.normalRangeMax,
    required this.createdAt,
    required this.updatedAt,
    this.valueType = 'numeric',
  });

  final int id;
  final String title;
  final String unit;
  final String normalRangeMin;
  final String normalRangeMax;
  final String createdAt;
  final String updatedAt;
  final String valueType;

  bool get isNumericValueType => valueType.toLowerCase() != 'string';

  MeasurementTitleModel copyWith({String? valueType}) => MeasurementTitleModel(
    id: id,
    title: title,
    unit: unit,
    normalRangeMin: normalRangeMin,
    normalRangeMax: normalRangeMax,
    createdAt: createdAt,
    updatedAt: updatedAt,
    valueType: valueType ?? this.valueType,
  );

  factory MeasurementTitleModel.fromJson(Map<String, dynamic> json) =>
      MeasurementTitleModel(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        unit: json['unit'] as String? ?? '',
        normalRangeMin: json['normal_range_min']?.toString() ?? '',
        normalRangeMax: json['normal_range_max']?.toString() ?? '',
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
        valueType: json['value_type'] as String? ?? 'numeric',
      );

  @override
  List<Object?> get props => [
    id,
    title,
    unit,
    normalRangeMin,
    normalRangeMax,
    createdAt,
    updatedAt,
    valueType,
  ];
}

class ClinicalNoteModel extends Equatable {
  const ClinicalNoteModel({
    required this.id,
    required this.admissionId,
    required this.addedBy,
    required this.type,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final int id;
  final int admissionId;
  final int addedBy;
  final String type;
  final String content;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  factory ClinicalNoteModel.fromJson(Map<String, dynamic> json) =>
      ClinicalNoteModel(
        id: json['id'] as int,
        admissionId: json['admission_id'] as int,
        addedBy: json['added_by'] as int,
        type: json['type'] as String? ?? '',
        content: json['content'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
        deletedAt: json['deleted_at'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    admissionId,
    addedBy,
    type,
    content,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}

class RadiologyImageModel extends Equatable {
  const RadiologyImageModel({
    required this.id,
    required this.admissionId,
    required this.title,
    required this.imagePath,
    required this.report,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final int id;
  final int admissionId;
  final String title;
  final String imagePath;
  final String report;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  factory RadiologyImageModel.fromJson(Map<String, dynamic> json) =>
      RadiologyImageModel(
        id: json['id'] as int,
        admissionId: json['admission_id'] as int,
        title: json['title'] as String? ?? '',
        imagePath: json['image_path'] as String? ?? '',
        report: json['report'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
        deletedAt: json['deleted_at'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    admissionId,
    title,
    imagePath,
    report,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}

class TreatmentPlanModel extends Equatable {
  const TreatmentPlanModel({
    required this.id,
    required this.admissionId,
    required this.planContent,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final int id;
  final int admissionId;
  final String planContent;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  factory TreatmentPlanModel.fromJson(Map<String, dynamic> json) =>
      TreatmentPlanModel(
        id: json['id'] as int,
        admissionId: json['admission_id'] as int,
        planContent: json['plan_content'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
        deletedAt: json['deleted_at'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    admissionId,
    planContent,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}

class VitalRecordModel extends Equatable {
  const VitalRecordModel({
    required this.id,
    required this.admissionId,
    required this.vitalsTitleId,
    required this.value,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.vitalsTitle,
  });

  final int id;
  final int admissionId;
  final int vitalsTitleId;
  final String value;
  final String date;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final MeasurementTitleModel? vitalsTitle;

  factory VitalRecordModel.fromJson(Map<String, dynamic> json) =>
      VitalRecordModel(
        id: json['id'] as int,
        admissionId: json['admission_id'] as int,
        vitalsTitleId: json['vitals_title_id'] as int,
        value: json['value']?.toString() ?? '',
        date: json['date'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
        deletedAt: json['deleted_at'] as String?,
        vitalsTitle: json['vitals_title'] != null
            ? MeasurementTitleModel.fromJson(
                json['vitals_title'] as Map<String, dynamic>,
              )
            : null,
      );

  @override
  List<Object?> get props => [
    id,
    admissionId,
    vitalsTitleId,
    value,
    date,
    createdAt,
    updatedAt,
    deletedAt,
    vitalsTitle,
  ];
}

class LabRecordModel extends Equatable {
  const LabRecordModel({
    required this.id,
    required this.admissionId,
    required this.labsTitleId,
    required this.value,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.labsTitle,
  });

  final int id;
  final int admissionId;
  final int labsTitleId;
  final String value;
  final String date;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final MeasurementTitleModel? labsTitle;

  factory LabRecordModel.fromJson(Map<String, dynamic> json) => LabRecordModel(
    id: json['id'] as int,
    admissionId: json['admission_id'] as int,
    labsTitleId: json['labs_title_id'] as int,
    value: json['value']?.toString() ?? '',
    date: json['date'] as String? ?? '',
    createdAt: json['created_at'] as String? ?? '',
    updatedAt: json['updated_at'] as String? ?? '',
    deletedAt: json['deleted_at'] as String?,
    labsTitle: json['labs_title'] != null
        ? MeasurementTitleModel.fromJson(
            json['labs_title'] as Map<String, dynamic>,
          )
        : null,
  );

  @override
  List<Object?> get props => [
    id,
    admissionId,
    labsTitleId,
    value,
    date,
    createdAt,
    updatedAt,
    deletedAt,
    labsTitle,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// Medication
// ═══════════════════════════════════════════════════════════════════════════════
class MedicationModel extends Equatable {
  const MedicationModel({
    required this.id,
    required this.admissionId,
    required this.type,
    required this.title,
    required this.value,
    required this.duration,
    required this.createdAt,
    required this.updatedAt,
    this.drugId,
    this.isDiscontinued = false,
    this.doseUnitId,
    this.doseUnitLabel = '',
  });

  final int id;
  final int admissionId;
  final String type;
  final String title;
  final String value;
  final String duration;
  final String createdAt;
  final String updatedAt;
  final int? drugId;
  final bool isDiscontinued;
  final int? doseUnitId;
  final String doseUnitLabel;

  MedicationModel copyWith({
    int? id,
    int? admissionId,
    String? type,
    String? title,
    String? value,
    String? duration,
    String? createdAt,
    String? updatedAt,
    int? drugId,
    bool? isDiscontinued,
    int? doseUnitId,
    String? doseUnitLabel,
  }) {
    return MedicationModel(
      id: id ?? this.id,
      admissionId: admissionId ?? this.admissionId,
      type: type ?? this.type,
      title: title ?? this.title,
      value: value ?? this.value,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      drugId: drugId ?? this.drugId,
      isDiscontinued: isDiscontinued ?? this.isDiscontinued,
      doseUnitId: doseUnitId ?? this.doseUnitId,
      doseUnitLabel: doseUnitLabel ?? this.doseUnitLabel,
    );
  }

  static bool _parseDiscontinued(Map<String, dynamic> json) {
    final raw = json['is_discontinued'] ?? json['discontinued'];
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final v = raw.trim().toLowerCase();
      return v == '1' || v == 'true' || v == 'yes';
    }
    final status = json['status']?.toString().trim().toLowerCase() ?? '';
    return status == 'discontinued' || status == 'stopped' || status == 'dc';
  }

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    final nestedDrug = json['drug'];
    String nestedTitle = '';
    int? nestedDrugId;
    if (nestedDrug is Map<String, dynamic>) {
      nestedDrugId = (nestedDrug['id'] as num?)?.toInt();
      nestedTitle =
          nestedDrug['generic_name']?.toString() ??
          nestedDrug['name']?.toString() ??
          '';
    }
    final dose = json['dose']?.toString() ?? json['value']?.toString() ?? '';
    final frequency =
        json['frequency']?.toString() ?? json['duration']?.toString() ?? '';
    final title = json['title']?.toString() ?? '';
    return MedicationModel(
      id: json['id'] as int,
      admissionId: json['admission_id'] as int,
      type: json['type'] as String? ?? '',
      title: title.isNotEmpty ? title : nestedTitle,
      value: dose,
      duration: frequency,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      drugId: (json['drug_id'] as num?)?.toInt() ?? nestedDrugId,
      isDiscontinued: _parseDiscontinued(json),
      doseUnitId:
          (json['dose_unit_id'] as num?)?.toInt() ??
          (json['dose_unit'] is Map<String, dynamic>
              ? (json['dose_unit']['id'] as num?)?.toInt()
              : null),
      doseUnitLabel: json['dose_unit'] is Map<String, dynamic>
          ? (json['dose_unit']['label']?.toString() ??
                json['dose_unit']['code']?.toString() ??
                '')
          : '',
    );
  }

  @override
  List<Object?> get props => [
    id,
    admissionId,
    type,
    title,
    value,
    duration,
    createdAt,
    updatedAt,
    drugId,
    isDiscontinued,
    doseUnitId,
    doseUnitLabel,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// Echo
// ═══════════════════════════════════════════════════════════════════════════════
class EchoModel extends Equatable {
  const EchoModel({
    required this.id,
    required this.admissionId,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int admissionId;
  final String text;
  final String createdAt;
  final String updatedAt;

  factory EchoModel.fromJson(Map<String, dynamic> json) => EchoModel(
    id: json['id'] as int,
    admissionId: json['admission_id'] as int,
    text: json['text'] as String? ?? '',
    createdAt: json['created_at'] as String? ?? '',
    updatedAt: json['updated_at'] as String? ?? '',
  );

  @override
  List<Object?> get props => [id, admissionId, text, createdAt, updatedAt];
}

// ═══════════════════════════════════════════════════════════════════════════════
// Ultrasound
// ═══════════════════════════════════════════════════════════════════════════════
class UltrasoundModel extends Equatable {
  const UltrasoundModel({
    required this.id,
    required this.admissionId,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int admissionId;
  final String text;
  final String createdAt;
  final String updatedAt;

  factory UltrasoundModel.fromJson(Map<String, dynamic> json) =>
      UltrasoundModel(
        id: json['id'] as int,
        admissionId: json['admission_id'] as int,
        text: json['text'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
      );

  @override
  List<Object?> get props => [id, admissionId, text, createdAt, updatedAt];
}

// ═══════════════════════════════════════════════════════════════════════════════
// Culture
// ═══════════════════════════════════════════════════════════════════════════════
class CultureAntibioticModel extends Equatable {
  const CultureAntibioticModel({
    required this.id,
    this.drugId,
    this.drugName = '',
    required this.sensitivity,
  });

  final int id;
  final int? drugId;
  final String drugName;
  final String sensitivity;

  String get displayName {
    final name = drugName.trim();
    if (name.isNotEmpty) return name;
    if (drugId != null) return 'Drug #$drugId';
    return 'Antibiotic';
  }

  factory CultureAntibioticModel.fromJson(Map<String, dynamic> json) {
    final nestedDrug = json['drug'];
    String name = json['drug_name']?.toString() ?? '';
    if (name.isEmpty && nestedDrug is Map<String, dynamic>) {
      name = nestedDrug['generic_name']?.toString() ?? '';
      final trades = nestedDrug['trade_names'];
      if (name.isNotEmpty && trades is List && trades.isNotEmpty) {
        name = '${trades.first} ($name)';
      }
    }
    return CultureAntibioticModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      drugId:
          (json['drug_id'] as num?)?.toInt() ??
          (nestedDrug is Map<String, dynamic>
              ? (nestedDrug['id'] as num?)?.toInt()
              : null),
      drugName: name,
      sensitivity: (json['sensitivity']?.toString() ?? 'S').toUpperCase(),
    );
  }

  @override
  List<Object?> get props => [id, drugId, drugName, sensitivity];
}

class CultureModel extends Equatable {
  const CultureModel({
    required this.id,
    required this.admissionId,
    required this.title,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    this.antibiotics = const [],
  });

  final int id;
  final int admissionId;
  final String title;
  final String note;
  final String createdAt;
  final String updatedAt;
  final List<CultureAntibioticModel> antibiotics;

  factory CultureModel.fromJson(Map<String, dynamic> json) => CultureModel(
    id: json['id'] as int,
    admissionId: json['admission_id'] as int,
    title: json['title'] as String? ?? '',
    note: json['note'] as String? ?? '',
    createdAt: json['created_at'] as String? ?? '',
    updatedAt: json['updated_at'] as String? ?? '',
    antibiotics: (json['antibiotics'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CultureAntibioticModel.fromJson)
        .toList(),
  );

  @override
  List<Object?> get props => [
    id,
    admissionId,
    title,
    note,
    createdAt,
    updatedAt,
    antibiotics,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// Consultation
// ═══════════════════════════════════════════════════════════════════════════════
class ConsultationModel extends Equatable {
  const ConsultationModel({
    required this.id,
    required this.admissionId,
    required this.speciality,
    required this.reply,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int admissionId;
  final String speciality;
  final String reply;
  final String createdAt;
  final String updatedAt;

  factory ConsultationModel.fromJson(Map<String, dynamic> json) =>
      ConsultationModel(
        id: json['id'] as int,
        admissionId: json['admission_id'] as int,
        speciality: json['speciality'] as String? ?? '',
        reply: json['reply'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
      );

  @override
  List<Object?> get props => [
    id,
    admissionId,
    speciality,
    reply,
    createdAt,
    updatedAt,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// HospitalGroup
// ═══════════════════════════════════════════════════════════════════════════════
class HospitalGroupModel extends Equatable {
  const HospitalGroupModel({
    required this.id,
    required this.hospitalId,
    required this.name,
    required this.totalBeds,
    required this.availableBeds,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int hospitalId;
  final String name;
  final int totalBeds;
  final int availableBeds;
  final String createdAt;
  final String updatedAt;

  factory HospitalGroupModel.fromJson(Map<String, dynamic> json) =>
      HospitalGroupModel(
        id: json['id'] as int,
        hospitalId: json['hospital_id'] as int,
        name: json['name'] as String? ?? '',
        totalBeds: (json['total_beds'] as num?)?.toInt() ?? 0,
        availableBeds: (json['available_beds'] as num?)?.toInt() ?? 0,
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
      );

  @override
  List<Object?> get props => [
    id,
    hospitalId,
    name,
    totalBeds,
    availableBeds,
    createdAt,
    updatedAt,
  ];
}

String _parseBedNumber(dynamic raw) {
  if (raw == null) return '';
  if (raw is String) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final parsed = int.tryParse(trimmed);
    return parsed != null ? '$parsed' : trimmed;
  }
  if (raw is num) return '${raw.toInt()}';
  final text = raw.toString().trim();
  if (text.isEmpty) return '';
  final parsed = int.tryParse(text);
  return parsed != null ? '$parsed' : text;
}

class PatientAdmissionModel extends Equatable {
  const PatientAdmissionModel({
    required this.id,
    required this.patientId,
    required this.hospitalId,
    required this.doctorId,
    this.hospitalGroupId,
    required this.bedNumber,
    required this.status,
    this.dateComes,
    this.dateLeave,
    this.dateOfDeath,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.patient,
    this.doctor,
    this.hospital,
    this.hospitalGroup,
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

  final int id;
  final int patientId;
  final int hospitalId;
  final int doctorId;
  final int? hospitalGroupId;
  final String bedNumber;
  final String status;
  final String? dateComes;
  final String? dateLeave;
  final String? dateOfDeath;
  final String notes;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final AdmissionPatientModel? patient;
  final UserModel? doctor;
  final HospitalModel? hospital;
  final HospitalGroupModel? hospitalGroup;
  final List<ClinicalNoteModel> clinicalNotes;
  final List<RadiologyImageModel> radiologyImages;
  final List<TreatmentPlanModel> treatmentPlans;
  final List<VitalRecordModel> vitals;
  final List<LabRecordModel> labs;
  final List<MedicationModel> medications;
  final List<EchoModel> echoes;
  final List<UltrasoundModel> ultrasounds;
  final List<CultureModel> cultures;
  final List<ConsultationModel> consultations;

  factory PatientAdmissionModel.fromJson(Map<String, dynamic> json) =>
      PatientAdmissionModel(
        id: (json['id'] as num).toInt(),
        patientId: (json['patient_id'] as num).toInt(),
        hospitalId: (json['hospital_id'] as num).toInt(),
        doctorId: (json['doctor_id'] as num).toInt(),
        hospitalGroupId: (json['hospital_group_id'] as num?)?.toInt(),
        bedNumber: _parseBedNumber(json['bed_number']),
        status: json['status'] as String? ?? '',
        dateComes: json['date_comes'] as String?,
        dateLeave: json['date_leave'] as String?,
        dateOfDeath: json['date_of_death'] as String?,
        notes: json['notes'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
        deletedAt: json['deleted_at'] as String?,
        patient: json['patient'] != null
            ? AdmissionPatientModel.fromJson(
                json['patient'] as Map<String, dynamic>,
              )
            : null,
        doctor: json['doctor'] != null
            ? UserModel.fromJson(json['doctor'] as Map<String, dynamic>)
            : null,
        hospital: json['hospital'] != null
            ? HospitalModel.fromJson(json['hospital'] as Map<String, dynamic>)
            : null,
        hospitalGroup: json['hospital_group'] != null
            ? HospitalGroupModel.fromJson(
                json['hospital_group'] as Map<String, dynamic>,
              )
            : null,
        clinicalNotes: (json['clinical_notes'] as List<dynamic>? ?? [])
            .map((e) => ClinicalNoteModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        radiologyImages: (json['radiology_images'] as List<dynamic>? ?? [])
            .map((e) => RadiologyImageModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        treatmentPlans: (json['treatment_plans'] as List<dynamic>? ?? [])
            .map((e) => TreatmentPlanModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        vitals: (json['vitals'] as List<dynamic>? ?? [])
            .map((e) => VitalRecordModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        labs: (json['labs'] as List<dynamic>? ?? [])
            .map((e) => LabRecordModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        medications: (json['medications'] as List<dynamic>? ?? [])
            .map((e) => MedicationModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        echoes: (json['echoes'] as List<dynamic>? ?? [])
            .map((e) => EchoModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        ultrasounds: (json['ultrasounds'] as List<dynamic>? ?? [])
            .map((e) => UltrasoundModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        cultures: (json['cultures'] as List<dynamic>? ?? [])
            .map((e) => CultureModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        consultations: (json['consultations'] as List<dynamic>? ?? [])
            .map((e) => ConsultationModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [
    id,
    patientId,
    hospitalId,
    doctorId,
    hospitalGroupId,
    bedNumber,
    status,
    dateComes,
    dateLeave,
    dateOfDeath,
    notes,
    createdAt,
    updatedAt,
    deletedAt,
    patient,
    doctor,
    hospital,
    clinicalNotes,
    radiologyImages,
    treatmentPlans,
    vitals,
    labs,
    medications,
    echoes,
    ultrasounds,
    cultures,
    consultations,
    hospitalGroup,
  ];
}
