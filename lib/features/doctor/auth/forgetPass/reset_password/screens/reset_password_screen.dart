import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/app_text_field.dart';

import '../../../login/screens/login_screen.dart';
import '../cubit/reset_password_cubit.dart';
import '../cubit/reset_password_state.dart';
import '../repository/reset_password_repository.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DoctorResetPasswordCubit(ResetPasswordRepository()),
      child: _ResetPasswordBody(email: email),
    );
  }
}

class _ResetPasswordBody extends StatefulWidget {
  const _ResetPasswordBody({required this.email});

  final String email;

  @override
  State<_ResetPasswordBody> createState() => _ResetPasswordBodyState();
}

class _ResetPasswordBodyState extends State<_ResetPasswordBody> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<DoctorResetPasswordCubit>().reset(
      email: widget.email,
      password: _passwordController.text,
      passwordConfirmation: _confirmController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DoctorResetPasswordCubit, DoctorResetPasswordState>(
      listener: (context, state) {
        if (state is DoctorResetPasswordSuccess) {
          final msg = state.response.message.isNotEmpty
              ? state.response.message
              : AppTexts.passwordResetSuccess;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(
              builder: (_) => LoginScreen(
                initialSnackMessage: msg,
                initialSnackSuccess: true,
              ),
            ),
            (_) => false,
          );
        }
        if (state is DoctorResetPasswordFailure) {
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
        final loading = state is DoctorResetPasswordLoading;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            title: const Text(
              AppTexts.resetPasswordTitle,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    AppTextField(
                      controller: _passwordController,
                      labelText: AppTexts.passwordLabel,
                      prefixIcon: const Icon(Icons.lock_outline),
                      isPassword: true,
                      textInputAction: TextInputAction.next,
                      enabled: !loading,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return AppTexts.passwordRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _confirmController,
                      labelText: AppTexts.confirmPasswordLabel,
                      prefixIcon: const Icon(Icons.lock_outline),
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      enabled: !loading,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return AppTexts.confirmPasswordRequired;
                        }
                        if (v != _passwordController.text) {
                          return AppTexts.passwordsDoNotMatch;
                        }
                        return null;
                      },
                    ),
                    const Spacer(),
                    AppButton(
                      label: AppTexts.resetPasswordButton,
                      onPressed: loading ? null : _submit,
                      isLoading: loading,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
