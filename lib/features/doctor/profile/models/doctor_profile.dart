import 'package:equatable/equatable.dart';

class HospitalPivot extends Equatable {
  const HospitalPivot({
    this.roleInHospital,
    this.status,
    this.requestedAt,
    this.actionedAt,
  });

  final String? roleInHospital;
  final String? status;
  final String? requestedAt;
  final String? actionedAt;

  factory HospitalPivot.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HospitalPivot();
    return HospitalPivot(
      roleInHospital: json['role_in_hospital'] as String?,
      status: json['status'] as String?,
      requestedAt: json['requested_at'] as String?,
      actionedAt: json['actioned_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [roleInHospital, status, requestedAt, actionedAt];
}

class ProfileHospital extends Equatable {
  const ProfileHospital({
    required this.id,
    required this.name,
    this.location,
    required this.totalBeds,
    required this.availableBeds,
    this.pivot,
  });

  final int id;
  final String name;
  final String? location;
  final int totalBeds;
  final int availableBeds;
  final HospitalPivot? pivot;

  factory ProfileHospital.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    return ProfileHospital(
      id: idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0,
      name: json['name'] as String? ?? '',
      location: json['location'] as String?,
      totalBeds: json['total_beds'] as int? ?? 0,
      availableBeds: json['available_beds'] as int? ?? 0,
      pivot: HospitalPivot.fromJson(json['pivot'] as Map<String, dynamic>?),
    );
  }

  @override
  List<Object?> get props =>
      [id, name, location, totalBeds, availableBeds, pivot];
}

class DoctorProfile extends Equatable {
  const DoctorProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
    this.lastLoginAt,
    this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.hospitals,
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isActive;
  final String? lastLoginAt;
  final String? emailVerifiedAt;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final List<ProfileHospital> hospitals;

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final hospitalsRaw = json['hospitals'] as List<dynamic>? ?? [];
    return DoctorProfile(
      id: idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      lastLoginAt: json['last_login_at'] as String?,
      emailVerifiedAt: json['email_verified_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      deletedAt: json['deleted_at'] as String?,
      hospitals: hospitalsRaw
          .map((e) => ProfileHospital.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        role,
        isActive,
        lastLoginAt,
        emailVerifiedAt,
        createdAt,
        updatedAt,
        deletedAt,
        hospitals,
      ];
}
