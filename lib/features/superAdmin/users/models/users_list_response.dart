import 'package:equatable/equatable.dart';

import '../../admins/models/pagination_model.dart';
import 'user_model.dart';

class UsersListResponse extends Equatable {
  const UsersListResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.pagination,
  });

  final bool success;
  final String message;
  final List<UserModel> data;
  final PaginationModel pagination;

  factory UsersListResponse.fromJson(Map<String, dynamic> json) =>
      UsersListResponse(
        success: json['success'] as bool,
        message: json['message'] as String,
        data: (json['data'] as List<dynamic>)
            .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        pagination: PaginationModel.fromJson(
            json['pagination'] as Map<String, dynamic>),
      );

  @override
  List<Object?> get props => [success, message, data, pagination];
}
