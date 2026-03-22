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

  const HospitalModel({
    required this.id,
    required this.name,
    required this.location,
    required this.totalBeds,
    required this.availableBeds,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  int get occupiedBeds => totalBeds - availableBeds;
  double get occupancyRate => totalBeds > 0 ? occupiedBeds / totalBeds : 0;

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    return HospitalModel(
      id: json['id'] as int,
      name: json['name'] as String,
      location: json['location'] as String,
      totalBeds: json['total_beds'] as int,
      availableBeds: json['available_beds'] as int,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      deletedAt: json['deleted_at'] as String?,
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
      ];
}
