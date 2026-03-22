import 'package:equatable/equatable.dart';

import '../../login/models/admin_model.dart';

/// Response wrapper for GET /auth/profile
///
/// ```json
/// { "success": true, "message": "...", "data": { ...AdminModel fields... } }
/// ```
class AdminProfileResponse extends Equatable {
  const AdminProfileResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final AdminModel data;

  factory AdminProfileResponse.fromJson(Map<String, dynamic> json) =>
      AdminProfileResponse(
        success: json['success'] as bool,
        message: json['message'] as String,
        data: AdminModel.fromJson(json['data'] as Map<String, dynamic>),
      );

  @override
  List<Object?> get props => [success, message, data];
}
