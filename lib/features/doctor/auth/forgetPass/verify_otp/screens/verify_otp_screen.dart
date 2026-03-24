import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import '../../reset_password/screens/reset_password_screen.dart';
import '../cubit/verify_otp_cubit.dart';
import '../cubit/verify_otp_state.dart';
import '../repository/verify_otp_repository.dart';

class VerifyOtpScreen extends StatelessWidget {
  const VerifyOtpScreen({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VerifyOtpCubit(VerifyOtpRepository()),
      child: _VerifyOtpBody(email: email),
    );
  }
}

class _VerifyOtpBody extends StatefulWidget {
  const _VerifyOtpBody({required this.email});

  final String email;

  @override
  State<_VerifyOtpBody> createState() => _VerifyOtpBodyState();
}

class _VerifyOtpBodyState extends State<_VerifyOtpBody> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<VerifyOtpCubit>().verify(
      email: widget.email,
      otpCode: _otpController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VerifyOtpCubit, VerifyOtpState>(
      listener: (context, state) {
        if (state is VerifyOtpSuccess) {
          final msg = state.response.message;
          if (msg.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ResetPasswordScreen(email: widget.email),
            ),
          );
        }
        if (state is VerifyOtpFailure) {
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
        final loading = state is VerifyOtpLoading;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            title: const Text(
              AppTexts.verifyOtpTitle,
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
                    Text(
                      'We sent a code to ${widget.email}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      enabled: !loading,
                      maxLength: 6,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                      ],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: AppTexts.otpLabel,
                        hintText: AppTexts.otpHint,
                        prefixIcon: Icon(Icons.pin_outlined),
                        counterText: '',
                      ),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return AppTexts.otpRequired;
                        if (t.length != 6) return AppTexts.otpInvalidLength;
                        return null;
                      },
                    ),
                    const Spacer(),
                    AppButton(
                      label: AppTexts.verifyOtpButton,
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
