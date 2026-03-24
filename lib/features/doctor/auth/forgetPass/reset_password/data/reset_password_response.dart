import 'package:equatable/equatable.dart';

class ResetPasswordFlowResponse extends Equatable {
  const ResetPasswordFlowResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final ResetPasswordFlowData data;

  factory ResetPasswordFlowResponse.fromJson(Map<String, dynamic> json) {
    return ResetPasswordFlowResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: ResetPasswordFlowData.fromJson(
        json['data'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}

class ResetPasswordFlowData extends Equatable {
  const ResetPasswordFlowData({required this.message});

  final String message;

  factory ResetPasswordFlowData.fromJson(Map<String, dynamic> json) {
    return ResetPasswordFlowData(message: json['message'] as String? ?? '');
  }

  @override
  List<Object?> get props => [message];
}
