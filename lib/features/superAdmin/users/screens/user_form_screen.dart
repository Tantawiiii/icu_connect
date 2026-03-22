import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../hospitals/models/hospital_model.dart';
import '../../hospitals/repository/hospitals_repository.dart';
import '../cubit/user_form_cubit.dart';
import '../cubit/user_form_state.dart';
import '../models/user_model.dart';
import '../models/user_request_model.dart';

// ── Entry class for a single hospital assignment in the form ──────────────────

class _HospitalEntry {
  _HospitalEntry({
    required this.hospitalId,
    required this.hospitalName,
    required this.role,
    this.status,
  });

  int hospitalId;
  String hospitalName;
  String role;
  String? status;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class UserFormScreen extends StatelessWidget {
  const UserFormScreen({super.key, this.user});

  /// Null = create mode, non-null = edit mode.
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UserFormCubit(),
      child: _UserFormView(user: user),
    );
  }
}

class _UserFormView extends StatefulWidget {
  const _UserFormView({this.user});

  final UserModel? user;

  @override
  State<_UserFormView> createState() => _UserFormViewState();
}

class _UserFormViewState extends State<_UserFormView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _confirmPasswordCtrl;

  String _selectedRole = 'doctor';
  bool _isActive = true;
  List<_HospitalEntry> _assignments = [];
  List<HospitalModel> _availableHospitals = [];
  bool _hospitalsLoading = true;

  static const _userRoles = ['admin', 'doctor', 'nurse', 'staff'];
  static const _hospitalRoles = ['admin', 'doctor', 'nurse', 'staff'];

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameCtrl = TextEditingController(text: u?.name ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _phoneCtrl = TextEditingController(text: u?.phone ?? '');
    _passwordCtrl = TextEditingController();
    _confirmPasswordCtrl = TextEditingController();
    _selectedRole = u?.role ?? 'doctor';
    _isActive = u?.isActive ?? true;

    if (u != null) {
      _assignments = u.hospitals
          .map((h) => _HospitalEntry(
                hospitalId: h.id,
                hospitalName: h.name,
                role: h.pivot.roleInHospital,
                status: h.pivot.status,
              ))
          .toList();
    }

    _loadHospitals();
  }

  Future<void> _loadHospitals() async {
    try {
      final response =
          await const HospitalsRepository().fetchHospitals(perPage: 100);
      if (mounted) {
        setState(() {
          _availableHospitals = response.data;
          _hospitalsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hospitalsLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final request = UserRequest(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      password:
          _passwordCtrl.text.isEmpty ? null : _passwordCtrl.text,
      passwordConfirmation: _confirmPasswordCtrl.text.isEmpty
          ? null
          : _confirmPasswordCtrl.text,
      role: _selectedRole,
      isActive: _isActive,
      hospitals: _assignments
          .map((a) => HospitalAssignment(
                hospitalId: a.hospitalId,
                roleInHospital: a.role,
                status: a.status,
              ))
          .toList(),
    );

    if (_isEdit) {
      context.read<UserFormCubit>().updateUser(widget.user!.id, request);
    } else {
      context.read<UserFormCubit>().createUser(request);
    }
  }

  void _showAddHospitalDialog() {
    final unassigned = _availableHospitals
        .where((h) => !_assignments.any((a) => a.hospitalId == h.id))
        .toList();

    if (unassigned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All available hospitals are already assigned'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    int selectedId = unassigned.first.id;
    String selectedRole = 'doctor';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text(AppTexts.addHospitalAssignment),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: AppTexts.hospitalsLabel,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                items: unassigned
                    .map((h) => DropdownMenuItem(
                          value: h.id,
                          child: Text(h.name,
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedId = v ?? selectedId),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: selectedRole,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: AppTexts.roleInHospital,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                items: _hospitalRoles
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                              r[0].toUpperCase() + r.substring(1)),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedRole = v ?? selectedRole),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(AppTexts.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final hospital = unassigned
                    .firstWhere((h) => h.id == selectedId);
                setState(() {
                  _assignments.add(_HospitalEntry(
                    hospitalId: hospital.id,
                    hospitalName: hospital.name,
                    role: selectedRole,
                  ));
                });
                Navigator.of(ctx).pop();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeAssignment(int index) {
    setState(() => _assignments.removeAt(index));
  }

  void _changeAssignmentRole(int index, String newRole) {
    setState(() => _assignments[index].role = newRole);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isEdit ? AppTexts.editUser : AppTexts.addUser,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<UserFormCubit, UserFormState>(
        listener: (context, state) {
          if (state is UserFormSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pop();
          }
          if (state is UserFormFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is UserFormLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Basic info ──────────────────────────────────────────
                  _SectionHeader('Basic Information'),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          AppTextField(
                            controller: _nameCtrl,
                            labelText: AppTexts.name,
                            prefixIcon:
                                const Icon(Icons.person_outline),
                            textInputAction: TextInputAction.next,
                            enabled: !isLoading,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _emailCtrl,
                            labelText: AppTexts.emailLabel,
                            prefixIcon:
                                const Icon(Icons.email_outlined),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            enabled: !isLoading,
                            autofillHints: const [AutofillHints.email],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return AppTexts.emailRequired;
                              }
                              if (!v.contains('@')) {
                                return AppTexts.emailInvalid;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _phoneCtrl,
                            labelText: AppTexts.phone,
                            prefixIcon:
                                const Icon(Icons.phone_outlined),
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            enabled: !isLoading,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Account settings ────────────────────────────────────
                  _SectionHeader('Account Settings'),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        // Role dropdown
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                          child: DropdownButtonFormField<String>(
                            value: _selectedRole,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: AppTexts.roleLabel,
                              prefixIcon:
                                  const Icon(Icons.manage_accounts_outlined),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            items: _userRoles
                                .map((r) => DropdownMenuItem(
                                      value: r,
                                      child: Text(r[0].toUpperCase() +
                                          r.substring(1)),
                                    ))
                                .toList(),
                            onChanged: isLoading
                                ? null
                                : (v) => setState(
                                    () => _selectedRole = v ?? _selectedRole),
                          ),
                        ),
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          title: Text(
                            _isActive
                                ? AppTexts.active
                                : AppTexts.inactive,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _isActive
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                          ),
                          subtitle: const Text(
                            'Enable or disable this account',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                          value: _isActive,
                          activeColor: AppColors.success,
                          onChanged: isLoading
                              ? null
                              : (v) => setState(() => _isActive = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Password ────────────────────────────────────────────
                  _SectionHeader(
                      _isEdit ? 'Change Password' : 'Password'),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          AppTextField(
                            controller: _passwordCtrl,
                            labelText: _isEdit
                                ? AppTexts.passwordLeaveBlank
                                : AppTexts.passwordLabel,
                            prefixIcon:
                                const Icon(Icons.lock_outline),
                            isPassword: true,
                            textInputAction: TextInputAction.next,
                            enabled: !isLoading,
                            autofillHints: const [
                              AutofillHints.newPassword
                            ],
                            validator: (v) {
                              if (!_isEdit &&
                                  (v == null || v.isEmpty)) {
                                return AppTexts.passwordRequired;
                              }
                              if (v != null &&
                                  v.isNotEmpty &&
                                  v.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _confirmPasswordCtrl,
                            labelText: _isEdit
                                ? AppTexts.confirmPasswordLeaveBlank
                                : AppTexts.confirmPassword,
                            prefixIcon:
                                const Icon(Icons.lock_outline),
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            enabled: !isLoading,
                            validator: (v) {
                              if (_passwordCtrl.text.isNotEmpty &&
                                  v != _passwordCtrl.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Hospital assignments ────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionHeader(AppTexts.assignedHospitals),
                      if (!isLoading)
                        TextButton.icon(
                          onPressed: _hospitalsLoading
                              ? null
                              : _showAddHospitalDialog,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text(
                              AppTexts.addHospitalAssignment),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: _hospitalsLoading
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary),
                              ),
                            ),
                          )
                        : _assignments.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: Text(
                                    AppTexts.noHospitalsAssigned,
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13),
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  for (int i = 0;
                                      i < _assignments.length;
                                      i++)
                                    _AssignmentRow(
                                      entry: _assignments[i],
                                      roles: _hospitalRoles,
                                      onRoleChanged: (r) =>
                                          _changeAssignmentRole(i, r),
                                      onRemove: () =>
                                          _removeAssignment(i),
                                      isLast: i ==
                                          _assignments.length - 1,
                                    ),
                                ],
                              ),
                  ),

                  const SizedBox(height: 28),

                  // ── Submit ──────────────────────────────────────────────
                  AppButton(
                    label:
                        _isEdit ? AppTexts.editUser : AppTexts.addUser,
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _submit,
                    leadingIcon: Icon(
                      _isEdit
                          ? Icons.save_outlined
                          : Icons.person_add_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Assignment row inside the card ────────────────────────────────────────────

class _AssignmentRow extends StatelessWidget {
  const _AssignmentRow({
    required this.entry,
    required this.roles,
    required this.onRoleChanged,
    required this.onRemove,
    required this.isLast,
  });

  final _HospitalEntry entry;
  final List<String> roles;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onRemove;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Hospital icon
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_hospital_outlined,
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),

              // Hospital name + role picker
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.hospitalName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonHideUnderline(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlpha(15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.accent.withAlpha(50)),
                        ),
                        child: DropdownButton<String>(
                          value: roles.contains(entry.role)
                              ? entry.role
                              : roles.first,
                          isDense: true,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          items: roles
                              .map((r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r[0].toUpperCase() +
                                        r.substring(1)),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) onRoleChanged(v);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Remove button
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: AppColors.error, size: 20),
                onPressed: onRemove,
                tooltip: 'Remove',
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 14, endIndent: 14,
              color: Color(0xFFEEEEEE)),
      ],
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}
