import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../login/models/admin_model.dart';
import '../cubit/admin_form_cubit.dart';
import '../cubit/admin_form_state.dart';
import '../models/admin_request_model.dart';
import '../repository/admins_repository.dart';

class AdminFormScreen extends StatelessWidget {
  const AdminFormScreen({super.key, this.admin});

  /// Null = create mode, non-null = edit mode.
  final AdminModel? admin;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminFormCubit(AdminsRepository()),
      child: _AdminFormView(admin: admin),
    );
  }
}

class _AdminFormView extends StatefulWidget {
  const _AdminFormView({this.admin});

  final AdminModel? admin;

  @override
  State<_AdminFormView> createState() => _AdminFormViewState();
}

class _AdminFormViewState extends State<_AdminFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _confirmPasswordCtrl;
  late bool _isActive;

  bool get _isEdit => widget.admin != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.admin?.name ?? '');
    _emailCtrl = TextEditingController(text: widget.admin?.email ?? '');
    _phoneCtrl = TextEditingController(text: widget.admin?.phone ?? '');
    _passwordCtrl = TextEditingController();
    _confirmPasswordCtrl = TextEditingController();
    _isActive = widget.admin?.isActive ?? true;
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

    final request = AdminRequest(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      isActive: _isActive,
      password: _passwordCtrl.text.isEmpty ? null : _passwordCtrl.text,
      passwordConfirmation: _confirmPasswordCtrl.text.isEmpty
          ? null
          : _confirmPasswordCtrl.text,
    );

    if (_isEdit) {
      context
          .read<AdminFormCubit>()
          .updateAdmin(widget.admin!.id, request);
    } else {
      context.read<AdminFormCubit>().createAdmin(request);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isEdit ? AppTexts.editAdmin : AppTexts.addAdmin,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<AdminFormCubit, AdminFormState>(
        listener: (context, state) {
          if (state is AdminFormSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pop();
          }
          if (state is AdminFormFailure) {
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
          final isLoading = state is AdminFormLoading;

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
                            prefixIcon: const Icon(Icons.person_outline),
                            textInputAction: TextInputAction.next,
                            enabled: !isLoading,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Name is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _emailCtrl,
                            labelText: AppTexts.emailLabel,
                            prefixIcon: const Icon(Icons.email_outlined),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            enabled: !isLoading,
                            autofillHints: const [AutofillHints.email],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return AppTexts.emailRequired;
                              if (!v.contains('@'))
                                return AppTexts.emailInvalid;
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _phoneCtrl,
                            labelText: AppTexts.phone,
                            prefixIcon: const Icon(Icons.phone_outlined),
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            enabled: !isLoading,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Status ──────────────────────────────────────────────
                  _SectionHeader('Account Status'),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      title: Text(
                        _isActive ? AppTexts.active : AppTexts.inactive,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _isActive
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ),
                      subtitle: const Text(
                        'Enable or disable this admin account',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      value: _isActive,
                      activeColor: AppColors.success,
                      onChanged: isLoading
                          ? null
                          : (v) => setState(() => _isActive = v),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Password ────────────────────────────────────────────
                  _SectionHeader(_isEdit ? 'Change Password' : 'Password'),
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
                            prefixIcon: const Icon(Icons.lock_outline),
                            isPassword: true,
                            textInputAction: TextInputAction.next,
                            enabled: !isLoading,
                            autofillHints: const [AutofillHints.newPassword],
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
                            prefixIcon: const Icon(Icons.lock_outline),
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

                  const SizedBox(height: 28),

                  // ── Submit ──────────────────────────────────────────────
                  AppButton(
                    label: _isEdit ? AppTexts.editAdmin : AppTexts.addAdmin,
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _submit,
                    leadingIcon: Icon(
                      _isEdit ? Icons.save_outlined : Icons.person_add_outlined,
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
