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

  factory HospitalDoctor.fromJson(
    Map<String, dynamic> json, {
    int? forHospitalId,
  }) {
    final idRaw = json['id'];
    String? roleInHospital = json['role_in_hospital'] as String?;
    String? status = json['status'] as String?;
    if (forHospitalId != null) {
      final hospitals = json['hospitals'] as List<dynamic>?;
      if (hospitals != null) {
        for (final raw in hospitals) {
          final m = raw as Map<String, dynamic>;
          final hidRaw = m['id'];
          final hid = hidRaw is int ? hidRaw : int.tryParse('$hidRaw') ?? 0;
          if (hid == forHospitalId) {
            roleInHospital = m['role_in_hospital'] as String? ?? roleInHospital;
            status = m['status'] as String? ?? status;
            break;
          }
        }
      }
    }
    return HospitalDoctor(
      id: idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? false,
      roleInHospital: roleInHospital,
      status: status,
    );
  }

  @override
  List<Object?> get props => [id, name, email, phone, role, isActive, roleInHospital, status];
}

