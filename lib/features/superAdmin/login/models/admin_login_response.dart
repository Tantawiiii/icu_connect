import 'package:equatable/equatable.dart';

import 'admin_model.dart';

/// Top-level response wrapper
/// ```json
/// { "success": true, "message": "...", "data": { ... } }
/// ```
class AdminLoginResponse extends Equatable {
  const AdminLoginResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final AdminLoginData data;

  factory AdminLoginResponse.fromJson(Map<String, dynamic> json) =>
      AdminLoginResponse(
        success: json['success'] as bool,
        message: json['message'] as String,
        data: AdminLoginData.fromJson(json['data'] as Map<String, dynamic>),
      );

  @override
  List<Object?> get props => [success, message, data];
}

/// Payload inside `data`
class AdminLoginData extends Equatable {
  const AdminLoginData({
    required this.message,
    required this.admin,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  final String message;
  final AdminModel admin;
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final String expiresIn;

  factory AdminLoginData.fromJson(Map<String, dynamic> json) => AdminLoginData(
        message: json['message'] as String,
        admin: AdminModel.fromJson(json['admin'] as Map<String, dynamic>),
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        tokenType: json['token_type'] as String,
        expiresIn: json['expires_in'] as String,
      );

  @override
  List<Object?> get props =>
      [message, admin, accessToken, refreshToken, tokenType, expiresIn];
}
