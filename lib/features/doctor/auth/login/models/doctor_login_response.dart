import 'package:equatable/equatable.dart';

class DoctorLoginResponse extends Equatable {
  const DoctorLoginResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final DoctorLoginData data;

  factory DoctorLoginResponse.fromJson(Map<String, dynamic> json) {
    return DoctorLoginResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: DoctorLoginData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}

class DoctorLoginData extends Equatable {
  const DoctorLoginData({
    required this.message,
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  final String message;
  final Map<String, dynamic> user;
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final String expiresIn;

  factory DoctorLoginData.fromJson(Map<String, dynamic> json) {
    return DoctorLoginData(
      message: json['message'] as String? ?? '',
      user: (json['user'] as Map<String, dynamic>?) ?? const {},
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'Bearer',
      expiresIn: json['expires_in'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
    message,
    user,
    accessToken,
    refreshToken,
    tokenType,
    expiresIn,
  ];
}
