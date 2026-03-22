import 'package:equatable/equatable.dart';

class VitalTitleModel extends Equatable {
  const VitalTitleModel({
    required this.id,
    required this.title,
    required this.unit,
    required this.normalRangeMin,
    required this.normalRangeMax,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String unit;
  final String normalRangeMin;
  final String normalRangeMax;
  final String createdAt;
  final String updatedAt;

  factory VitalTitleModel.fromJson(Map<String, dynamic> json) =>
      VitalTitleModel(
        id: json['id'] as int,
        title: json['title'] as String,
        unit: json['unit'] as String? ?? '',
        normalRangeMin: json['normal_range_min']?.toString() ?? '',
        normalRangeMax: json['normal_range_max']?.toString() ?? '',
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
      );

  @override
  List<Object?> get props =>
      [id, title, unit, normalRangeMin, normalRangeMax, createdAt, updatedAt];
}

