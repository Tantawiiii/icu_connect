/// Request body for POST /admins and PUT /admins/{id}
class AdminRequest {
  const AdminRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.isActive,
    this.password,
    this.passwordConfirmation,
  });

  final String name;
  final String email;
  final String phone;
  final bool isActive;

  /// Required for create, optional for update (leave null to keep current).
  final String? password;
  final String? passwordConfirmation;

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'is_active': isActive ? 'true' : 'false',
        if (password != null && password!.isNotEmpty) 'password': password,
        if (passwordConfirmation != null &&
            passwordConfirmation!.isNotEmpty)
          'password_confirmation': passwordConfirmation,
      };
}
