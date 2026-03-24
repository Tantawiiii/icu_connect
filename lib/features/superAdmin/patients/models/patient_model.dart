import 'package:equatable/equatable.dart';

import 'patient_admission_models.dart';

class PatientModel extends Equatable {
  const PatientModel({
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
    this.admissions = const [],
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
  final List<PatientAdmissionModel> admissions;

  bool get isDeleted => deletedAt != null;

  factory PatientModel.fromJson(Map<String, dynamic> json) => PatientModel(
        id: json['id'] as int,
        name: json['name'] as String,
        nationalId: json['national_id']?.toString() ?? '',
        age: json['age'] as int,
        gender: json['gender'] as String,
        phone: json['phone'] as String? ?? '',
        bloodGroup: json['blood_group'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
        deletedAt: json['deleted_at'] as String?,
        admissions: (json['admissions'] as List<dynamic>? ?? [])
            .map((e) =>
                PatientAdmissionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
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
        admissions,
      ];
}

