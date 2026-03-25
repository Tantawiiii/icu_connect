import 'package:equatable/equatable.dart';

class HospitalDoctor extends Equatable {
  const HospitalDoctor({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
    this.roleInHospital,
    this.status,
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isActive;
  final String? roleInHospital;
  final String? status;

  factory HospitalDoctor.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    return HospitalDoctor(
      id: idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? false,
      roleInHospital: json['role_in_hospital'] as String?,
      status: json['status'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, email, phone, role, isActive, roleInHospital, status];
}

