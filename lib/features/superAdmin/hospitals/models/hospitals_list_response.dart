import 'package:equatable/equatable.dart';

import '../../admins/models/pagination_model.dart';
import 'hospital_model.dart';

class HospitalsListResponse extends Equatable {
  const HospitalsListResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.pagination,
  });

  final bool success;
  final String message;
  final List<HospitalModel> data;
  final PaginationModel pagination;

  factory HospitalsListResponse.fromJson(Map<String, dynamic> json) =>
      HospitalsListResponse(
        success: json['success'] as bool,
        message: json['message'] as String,
        data: (json['data'] as List<dynamic>)
            .map((e) => HospitalModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        pagination: PaginationModel.fromJson(
            json['pagination'] as Map<String, dynamic>),
      );

  @override
  List<Object?> get props => [success, message, data, pagination];
}
