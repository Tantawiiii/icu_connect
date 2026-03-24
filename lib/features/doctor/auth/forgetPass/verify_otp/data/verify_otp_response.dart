import 'package:equatable/equatable.dart';

class VerifyOtpResponse extends Equatable {
  const VerifyOtpResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final VerifyOtpData data;

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: VerifyOtpData.fromJson(json['data'] as Map<String, dynamic>? ?? {}),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}

class VerifyOtpData extends Equatable {
  const VerifyOtpData({required this.message});

  final String message;

  factory VerifyOtpData.fromJson(Map<String, dynamic> json) {
    return VerifyOtpData(message: json['message'] as String? ?? '');
  }

  @override
  List<Object?> get props => [message];
}
