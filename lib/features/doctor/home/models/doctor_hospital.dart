import 'package:equatable/equatable.dart';

class HospitalUserStatus extends Equatable {
  const HospitalUserStatus({
    required this.isAssigned,
    this.status,
    this.roleInHospital,
    this.approvedBy,
    this.requestedAt,
    this.actionedAt,
    required this.canRequest,
  });

  final bool isAssigned;
  final String? status;
  final String? roleInHospital;
  final int? approvedBy;
  final String? requestedAt;
  final String? actionedAt;
  final bool canRequest;

  factory HospitalUserStatus.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const HospitalUserStatus(isAssigned: false, canRequest: false);
    }
    return HospitalUserStatus(
      isAssigned: json['is_assigned'] as bool? ?? false,
      status: json['status'] as String?,
      roleInHospital: json['role_in_hospital'] as String?,
      approvedBy: json['approved_by'] as int?,
      requestedAt: json['requested_at'] as String?,
      actionedAt: json['actioned_at'] as String?,
      canRequest: json['can_request'] as bool? ?? false,
    );
  }

  bool get hasAccess {
    if (!isAssigned) return false;
    final normalized = status?.toLowerCase().trim();
    return normalized == 'approved' ||
        normalized == 'active' ||
        normalized == 'accepted';
  }

  @override
  List<Object?> get props => [
    isAssigned,
    status,
    roleInHospital,
    approvedBy,
    requestedAt,
    actionedAt,
    canRequest,
  ];
}

class DoctorHospital extends Equatable {
  const DoctorHospital({
    required this.id,
    required this.name,
    this.location,
    required this.totalBeds,
    required this.availableBeds,
    required this.userStatus,
  });

  final int id;
  final String name;
  final String? location;
  final int totalBeds;
  final int availableBeds;
  final HospitalUserStatus userStatus;

  bool get isUnlocked => userStatus.hasAccess;

  factory DoctorHospital.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    return DoctorHospital(
      id: idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0,
      name: json['name'] as String? ?? '',
      location: json['location'] as String?,
      totalBeds: json['total_beds'] as int? ?? 0,
      availableBeds: json['available_beds'] as int? ?? 0,
      userStatus: HospitalUserStatus.fromJson(
        json['user_status'] as Map<String, dynamic>?,
      ),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    location,
    totalBeds,
    availableBeds,
    userStatus,
  ];
}
