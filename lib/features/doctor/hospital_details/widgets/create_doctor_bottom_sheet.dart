import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/app_text_field.dart';

import '../cubit/hospital_doctors_cubit.dart';
import '../cubit/hospital_doctors_state.dart';

class CreateDoctorBottomSheet extends StatefulWidget {
  const CreateDoctorBottomSheet({
    super.key,
    required this.hospitalId,
    required this.onCreated,
  });

  final int hospitalId;
  final VoidCallback onCreated;

  @override
  State<CreateDoctorBottomSheet> createState() => _CreateDoctorBottomSheetState();
}

class _CreateDoctorBottomSheetState extends State<CreateDoctorBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _passCtrl;
  late final TextEditingController _confirmCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _passCtrl = TextEditingController();
    _confirmCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(bool creating) async {
    if (creating) return;
    if (!_formKey.currentState!.validate()) return;
    await context.read<HospitalDoctorsCubit>().createDoctor(
          hospitalId: widget.hospitalId,
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          password: _passCtrl.text,
          passwordConfirmation: _confirmCtrl.text,
        );
    widget.onCreated();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HospitalDoctorsCubit, HospitalDoctorsState>(
      builder: (context, state) {
        final creating =
            state is HospitalDoctorsLoaded ? state.creating : false;
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottomInset),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          AppTexts.createDoctor,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: creating ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _nameCtrl,
                    labelText: AppTexts.doctorName,
                    prefixIcon: const Icon(Icons.person_outline),
                    textInputAction: TextInputAction.next,
                    enabled: !creating,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? AppTexts.nameRequired : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _emailCtrl,
                    labelText: AppTexts.emailLabel,
                    prefixIcon: const Icon(Icons.email_outlined),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !creating,
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return AppTexts.emailRequired;
                      if (!t.contains('@')) return AppTexts.emailInvalid;
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _phoneCtrl,
                    labelText: AppTexts.phone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    enabled: !creating,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? AppTexts.phoneRequired : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _passCtrl,
                    labelText: AppTexts.passwordLabel,
                    prefixIcon: const Icon(Icons.lock_outline),
                    isPassword: true,
                    textInputAction: TextInputAction.next,
                    enabled: !creating,
                    validator: (v) {
                      if (v == null || v.isEmpty) return AppTexts.passwordRequired;
                      if (v.length < 8) return AppTexts.passwordMustBeAtLeast8Characters;
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _confirmCtrl,
                    labelText: AppTexts.confirmPasswordLabel,
                    prefixIcon: const Icon(Icons.lock_outline),
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    enabled: !creating,
                    onFieldSubmitted: (_) => _submit(creating),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return AppTexts.confirmPasswordRequired;
                      }
                      if (v != _passCtrl.text) return AppTexts.passwordsDoNotMatch;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: AppTexts.createDoctor,
                    isLoading: creating,
                    onPressed: creating ? null : () => _submit(creating),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

