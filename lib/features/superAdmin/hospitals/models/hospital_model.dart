import 'package:equatable/equatable.dart';

class HospitalModel extends Equatable {
  final int id;
  final String name;
  final String location;
  final int totalBeds;
  final int availableBeds;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final List<HospitalGroupModel> groups;

  const HospitalModel({
    required this.id,
    required this.name,
    required this.location,
    required this.totalBeds,
    required this.availableBeds,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.groups = const [],
  });

  bool get isDeleted => deletedAt != null;
  int get occupiedBeds => totalBeds - availableBeds;
  double get occupancyRate => totalBeds > 0 ? occupiedBeds / totalBeds : 0;

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    final groups = (json['groups'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(HospitalGroupModel.fromJson)
        .toList();
    final totalBedsRaw = (json['total_beds'] as num?)?.toInt();
    final availableBedsRaw = (json['available_beds'] as num?)?.toInt();
    final totalBedsFromGroups =
        groups.fold<int>(0, (sum, g) => sum + g.totalBeds);
    final availableBedsFromGroups =
        groups.fold<int>(0, (sum, g) => sum + g.availableBeds);

    return HospitalModel(
      id: json['id'] as int,
      name: json['name'] as String,
      location: json['location'] as String,
      totalBeds: totalBedsRaw ?? totalBedsFromGroups,
      availableBeds: availableBedsRaw ?? availableBedsFromGroups,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      deletedAt: json['deleted_at'] as String?,
      groups: groups,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'total_beds': totalBeds,
        'available_beds': availableBeds,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
        'groups': groups.map((g) => g.toJson()).toList(),
      };

  @override
  List<Object?> get props => [
        id,
        name,
        location,
        totalBeds,
        availableBeds,
        createdAt,
        updatedAt,
        deletedAt,
        groups,
      ];
}

class HospitalGroupModel extends Equatable {
  final int? id;
  final String name;
  final int totalBeds;
  final int availableBeds;

  const HospitalGroupModel({
    this.id,
    required this.name,
    required this.totalBeds,
    required this.availableBeds,
  });

  factory HospitalGroupModel.fromJson(Map<String, dynamic> json) {
    return HospitalGroupModel(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String? ?? '',
      totalBeds: (json['total_beds'] as num?)?.toInt() ?? 0,
      availableBeds: (json['available_beds'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'total_beds': totalBeds,
        'available_beds': availableBeds,
      };

  @override
  List<Object?> get props => [id, name, totalBeds, availableBeds];
}
