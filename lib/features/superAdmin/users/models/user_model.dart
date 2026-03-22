import 'package:equatable/equatable.dart';

class UserHospitalPivot extends Equatable {
  const UserHospitalPivot({
    required this.roleInHospital,
    required this.status,
  });

  final String roleInHospital;
  final String status;

  factory UserHospitalPivot.fromJson(Map<String, dynamic> json) =>
      UserHospitalPivot(
        roleInHospital: json['role_in_hospital'] as String? ?? '',
        status: json['status'] as String? ?? '',
      );

  @override
  List<Object?> get props => [roleInHospital, status];
}

class UserHospitalModel extends Equatable {
  const UserHospitalModel({
    required this.id,
    required this.name,
    required this.location,
    required this.pivot,
  });

  final int id;
  final String name;
  final String location;
  final UserHospitalPivot pivot;

  factory UserHospitalModel.fromJson(Map<String, dynamic> json) =>
      UserHospitalModel(
        id: json['id'] as int,
        name: json['name'] as String,
        location: json['location'] as String? ?? '',
        pivot: UserHospitalPivot.fromJson(
            json['pivot'] as Map<String, dynamic>),
      );

  @override
  List<Object?> get props => [id, name, location, pivot];
}

class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    this.emailVerifiedAt,
    this.deletedAt,
    this.hospitals = const [],
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
  final List<UserHospitalModel> hospitals;

  bool get isDeleted => deletedAt != null;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String? ?? '',
        role: json['role'] as String,
        isActive: json['is_active'] as bool,
        lastLoginAt: json['last_login_at'] as String?,
        emailVerifiedAt: json['email_verified_at'] as String?,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
        deletedAt: json['deleted_at'] as String?,
        hospitals: (json['hospitals'] as List<dynamic>? ?? [])
            .map((e) =>
                UserHospitalModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

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
