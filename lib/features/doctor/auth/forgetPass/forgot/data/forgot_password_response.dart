import 'package:equatable/equatable.dart';

class ForgotPasswordResponse extends Equatable {
  const ForgotPasswordResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final ForgotPasswordData data;

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: ForgotPasswordData.fromJson(
        json['data'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}

class ForgotPasswordData extends Equatable {
  const ForgotPasswordData({required this.message});

  final String message;

  factory ForgotPasswordData.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordData(message: json['message'] as String? ?? '');
  }

  @override
  List<Object?> get props => [message];
}
