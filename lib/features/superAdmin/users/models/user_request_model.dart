class HospitalAssignment {
  const HospitalAssignment({
    required this.hospitalId,
    required this.roleInHospital,
    this.status,
  });

  final int hospitalId;
  final String roleInHospital;
  final String? status;

  Map<String, dynamic> toJson() => {
        'hospital_id': hospitalId,
        'role_in_hospital': roleInHospital,
        if (status != null) 'status': status,
      };
}

class UserRequest {
  const UserRequest({
    this.name,
    this.email,
    this.phone,
    this.password,
    this.passwordConfirmation,
    this.role,
    this.isActive,
    this.hospitals,
  });

  final String? name;
  final String? email;
  final String? phone;
  final String? password;
  final String? passwordConfirmation;
  final String? role;
  final bool? isActive;
  final List<HospitalAssignment>? hospitals;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (email != null) map['email'] = email;
    if (phone != null) map['phone'] = phone;
    if (password != null && password!.isNotEmpty) {
      map['password'] = password;
    }
    if (passwordConfirmation != null && passwordConfirmation!.isNotEmpty) {
      map['password_confirmation'] = passwordConfirmation;
    }
    if (role != null) map['role'] = role;
    if (isActive != null) map['is_active'] = isActive.toString();
    if (hospitals != null) {
      map['hospitals'] = hospitals!.map((h) => h.toJson()).toList();
    }
    return map;
  }
}
