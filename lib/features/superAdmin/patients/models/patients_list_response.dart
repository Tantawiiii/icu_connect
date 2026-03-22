import 'package:equatable/equatable.dart';

import '../../admins/models/pagination_model.dart';
import 'patient_model.dart';

class PatientsListResponse extends Equatable {
  const PatientsListResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.pagination,
  });

  final bool success;
  final String message;
  final List<PatientModel> data;
  final PaginationModel pagination;

  factory PatientsListResponse.fromJson(Map<String, dynamic> json) =>
      PatientsListResponse(
        success: json['success'] as bool,
        message: json['message'] as String,
        data: (json['data'] as List<dynamic>)
            .map((e) => PatientModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        pagination: PaginationModel.fromJson(
            json['pagination'] as Map<String, dynamic>),
      );

  @override
  List<Object?> get props => [success, message, data, pagination];
}

