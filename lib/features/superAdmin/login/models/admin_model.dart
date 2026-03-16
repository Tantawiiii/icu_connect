import 'package:equatable/equatable.dart';

class AdminModel extends Equatable {
  const AdminModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
    required this.lastLoginAt,
    required this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
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

  factory AdminModel.fromJson(Map<String, dynamic> json) => AdminModel(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: (json['phone'] ?? '') as String,
        role: json['role'] as String,
        isActive: json['is_active'] as bool? ?? false,
        lastLoginAt: json['last_login_at'] as String?,
        emailVerifiedAt: json['email_verified_at'] as String?,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
        deletedAt: json['deleted_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'is_active': isActive,
        'last_login_at': lastLoginAt,
        'email_verified_at': emailVerifiedAt,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
      };

  bool get isSuperAdmin => role == 'super_admin';

  @override
  List<Object?> get props => [
        id, name, email, phone, role, isActive,
        lastLoginAt, emailVerifiedAt, createdAt, updatedAt, deletedAt,
      ];
}
