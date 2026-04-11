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
  });

  final int id;
  final String title;
  final String unit;
  final String normalRangeMin;
  final String normalRangeMax;
  final String createdAt;
  final String updatedAt;

  factory MeasurementTitleModel.fromJson(Map<String, dynamic> json) =>
      MeasurementTitleModel(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        unit: json['unit'] as String? ?? '',
        normalRangeMin: json['normal_range_min']?.toString() ?? '',
        normalRangeMax: json['normal_range_max']?.toString() ?? '',
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
      );

  @override
  List<Object?> get props =>
      [id, title, unit, normalRangeMin, normalRangeMax, createdAt, updatedAt];
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
  List<Object?> get props =>
      [id, admissionId, addedBy, type, content, createdAt, updatedAt, deletedAt];
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
  List<Object?> get props =>
      [id, admissionId, planContent, createdAt, updatedAt, deletedAt];
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
  });

  final int id;
  final int admissionId;
  final String type;
  final String title;
  final String value;
  final String duration;
  final String createdAt;
  final String updatedAt;

  factory MedicationModel.fromJson(Map<String, dynamic> json) => MedicationModel(
        id: json['id'] as int,
        admissionId: json['admission_id'] as int,
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? '',
        value: json['value'] as String? ?? '',
        duration: json['duration'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
      );

  @override
  List<Object?> get props => [id, admissionId, type, title, value, duration, createdAt, updatedAt];
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

  factory UltrasoundModel.fromJson(Map<String, dynamic> json) => UltrasoundModel(
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
class CultureModel extends Equatable {
  const CultureModel({
    required this.id,
    required this.admissionId,
    required this.title,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int admissionId;
  final String title;
  final String note;
  final String createdAt;
  final String updatedAt;

  factory CultureModel.fromJson(Map<String, dynamic> json) => CultureModel(
        id: json['id'] as int,
        admissionId: json['admission_id'] as int,
        title: json['title'] as String? ?? '',
        note: json['note'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
      );

  @override
  List<Object?> get props => [id, admissionId, title, note, createdAt, updatedAt];
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

  factory HospitalGroupModel.fromJson(Map<String, dynamic> json) => HospitalGroupModel(
        id: json['id'] as int,
        hospitalId: json['hospital_id'] as int,
        name: json['name'] as String? ?? '',
        totalBeds: (json['total_beds'] as num?)?.toInt() ?? 0,
        availableBeds: (json['available_beds'] as num?)?.toInt() ?? 0,
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
      );

  @override
  List<Object?> get props => [id, hospitalId, name, totalBeds, availableBeds, createdAt, updatedAt];
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

  factory PatientAdmissionModel.fromJson(Map<String, dynamic> json) =>
      PatientAdmissionModel(
        id: json['id'] as int,
        patientId: json['patient_id'] as int,
        hospitalId: json['hospital_id'] as int,
        doctorId: json['doctor_id'] as int,
        hospitalGroupId: (json['hospital_group_id'] as num?)?.toInt(),
        bedNumber: json['bed_number'] as String? ?? '',
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
            ? HospitalGroupModel.fromJson(json['hospital_group'] as Map<String, dynamic>)
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
        hospitalGroup,
      ];
}
