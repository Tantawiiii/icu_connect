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

/// ICU group / ward returned under `hospital.groups` from the API.
class HospitalGroup extends Equatable {
  const HospitalGroup({
    required this.id,
    required this.name,
    required this.totalBeds,
    required this.availableBeds,
  });

  final int id;
  final String name;
  final int totalBeds;
  final int availableBeds;

  factory HospitalGroup.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    return HospitalGroup(
      id: idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0,
      name: json['name'] as String? ?? '',
      totalBeds: json['total_beds'] as int? ?? 0,
      availableBeds: json['available_beds'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name, totalBeds, availableBeds];
}

class DoctorHospital extends Equatable {
  const DoctorHospital({
    required this.id,
    required this.name,
    this.location,
    required this.totalBeds,
    required this.availableBeds,
    required this.groupsCount,
    required this.userStatus,
    this.groups = const [],
  });

  final int id;
  final String name;
  final String? location;
  final int totalBeds;
  final int availableBeds;
  final int groupsCount;
  final HospitalUserStatus userStatus;
  final List<HospitalGroup> groups;

  bool get isUnlocked => userStatus.hasAccess;

  factory DoctorHospital.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final groupsRaw = json['groups'] as List<dynamic>?;
    final groupsList = <HospitalGroup>[];
    if (groupsRaw != null) {
      for (final e in groupsRaw) {
        if (e is Map<String, dynamic>) {
          groupsList.add(HospitalGroup.fromJson(e));
        }
      }
    }
    return DoctorHospital(
      id: idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0,
      name: json['name'] as String? ?? '',
      location: json['location'] as String?,
      totalBeds: json['total_beds'] as int? ?? 0,
      availableBeds: json['available_beds'] as int? ?? 0,
      groupsCount: groupsList.isNotEmpty ? groupsList.length : (groupsRaw?.length ?? 0),
      groups: groupsList,
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
    groupsCount,
    userStatus,
    groups,
  ];
}
