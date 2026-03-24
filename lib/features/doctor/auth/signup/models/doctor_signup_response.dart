import 'package:equatable/equatable.dart';

class DoctorSignupResponse extends Equatable {
  const DoctorSignupResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final DoctorSignupPayload data;

  factory DoctorSignupResponse.fromJson(Map<String, dynamic> json) {
    return DoctorSignupResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: DoctorSignupPayload.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}

class DoctorSignupPayload extends Equatable {
  const DoctorSignupPayload({required this.user});

  final SignupRegisteredUser user;

  factory DoctorSignupPayload.fromJson(Map<String, dynamic> json) {
    return DoctorSignupPayload(
      user: SignupRegisteredUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [user];
}

class SignupRegisteredUser extends Equatable {
  const SignupRegisteredUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isActive;

  factory SignupRegisteredUser.fromJson(Map<String, dynamic> json) {
    return SignupRegisteredUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: (json['phone'] ?? '') as String,
      role: json['role'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, name, email, phone, role, isActive];
}
