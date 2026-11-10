import 'package:equatable/equatable.dart';

import 'hospital_model.dart';

class HospitalRegistrationRequest extends Equatable {
  final int id;
  final String name;
  final String location;
  final String approvalStatus;
  final int totalBeds;
  final int availableBeds;
  final String? createdAt;
  final String? updatedAt;
  final List<HospitalGroupModel> groups;

  const HospitalRegistrationRequest({
    required this.id,
    required this.name,
    required this.location,
    required this.approvalStatus,
    required this.totalBeds,
    required this.availableBeds,
    this.createdAt,
    this.updatedAt,
    this.groups = const [],
  });

  bool get isPending => approvalStatus.toLowerCase() == 'pending';
  bool get isAccepted => approvalStatus.toLowerCase() == 'accepted';
  bool get isRejected => approvalStatus.toLowerCase() == 'rejected';
  int get occupiedBeds => totalBeds - availableBeds;

  factory HospitalRegistrationRequest.fromJson(Map<String, dynamic> json) {
    final groups = (json['groups'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(HospitalGroupModel.fromJson)
        .toList();
    final totalBedsRaw = (json['total_beds'] as num?)?.toInt();
    final availableBedsRaw = (json['available_beds'] as num?)?.toInt();
    final totalBedsFromGroups = groups.fold<int>(
      0,
      (sum, g) => sum + g.totalBeds,
    );
    final availableBedsFromGroups = groups.fold<int>(
      0,
      (sum, g) => sum + g.availableBeds,
    );

    return HospitalRegistrationRequest(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      approvalStatus: json['approval_status'] as String? ?? 'pending',
      totalBeds: totalBedsRaw ?? totalBedsFromGroups,
      availableBeds: availableBedsRaw ?? availableBedsFromGroups,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      groups: groups,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    location,
    approvalStatus,
    totalBeds,
    availableBeds,
    createdAt,
    updatedAt,
    groups,
  ];
}
