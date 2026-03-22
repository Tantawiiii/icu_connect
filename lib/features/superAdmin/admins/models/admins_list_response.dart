import 'package:equatable/equatable.dart';

import '../../login/models/admin_model.dart';
import 'pagination_model.dart';

class AdminsListResponse extends Equatable {
  const AdminsListResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.pagination,
  });

  final bool success;
  final String message;
  final List<AdminModel> data;
  final PaginationModel pagination;

  factory AdminsListResponse.fromJson(Map<String, dynamic> json) =>
      AdminsListResponse(
        success: json['success'] as bool,
        message: json['message'] as String,
        data: (json['data'] as List<dynamic>)
            .map((e) => AdminModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        pagination: PaginationModel.fromJson(
            json['pagination'] as Map<String, dynamic>),
      );

  @override
  List<Object?> get props => [success, message, data, pagination];
}
