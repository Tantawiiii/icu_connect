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
import '../models/hospital_entry.dart';
import '../models/user_model.dart';
import '../models/user_request_model.dart';
import '../widgets/hospital_assignment_row.dart';
import '../widgets/section_header.dart';

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
  List<HospitalEntry> _assignments = [];
  List<HospitalModel> _availableHospitals = [];
  bool _hospitalsLoading = true;

  static const _userRoles = ['admin', 'doctor', 'nurse', 'staff'];
  static const _hospitalRoles = ['admin', 'doctor', 'nurse', 'staff'];
  static const _hospitalStatuses = ['pending', 'accepted', 'rejected'];

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
          .map((h) => HospitalEntry(
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
          content: Text(AppTexts.allHospitalsAlreadyAssigned),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    int selectedId = unassigned.first.id;
    String selectedRole = 'doctor';
    String selectedStatus = 'pending';

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
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: AppTexts.status,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                items: _hospitalStatuses
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s[0].toUpperCase() + s.substring(1)),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedStatus = v ?? selectedStatus),
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
                  _assignments.add(HospitalEntry(
                    hospitalId: hospital.id,
                    hospitalName: hospital.name,
                    role: selectedRole,
                    status: selectedStatus,
                  ));
                });
                Navigator.of(ctx).pop();
              },
              child: const Text(AppTexts.add),
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

  void _changeAssignmentStatus(int index, String newStatus) {
    setState(() => _assignments[index].status = newStatus);
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
                  SectionHeader(AppTexts.basicInformation),
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
                                return AppTexts.nameRequired;
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
                  SectionHeader(AppTexts.accountSettings),
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
                            AppTexts.enableOrDisableThisAccount,
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
                  SectionHeader(
                    _isEdit ? AppTexts.changePassword : AppTexts.passwordLabel,
                  ),
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
                                return AppTexts.passwordMustBeAtLeast8Characters;
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
                                return AppTexts.passwordsDoNotMatch;
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
                      SectionHeader(AppTexts.assignedHospitals),
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
                                    HospitalAssignmentRow(
                                      entry: _assignments[i],
                                      roles: _hospitalRoles,
                                      statuses: _hospitalStatuses,
                                      onRoleChanged: (r) =>
                                          _changeAssignmentRole(i, r),
                                      onStatusChanged: (s) =>
                                          _changeAssignmentStatus(i, s),
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

// Widgets moved to `lib/features/superAdmin/users/widgets/`.
