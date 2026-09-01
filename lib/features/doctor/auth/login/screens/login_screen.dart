import 'package:bounce/bounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_images.dart';
import 'package:icu_connect/core/constants/app_spacing.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/network/api_client.dart';
import 'package:icu_connect/core/network/api_constants.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/app_text_field.dart';

import '../../../../superAdmin/login/widgets/admin_login_dialog.dart';
import '../../../home/screens/main_screen.dart';
import '../../forgetPass/forgot/screens/forgot_password_screen.dart';
import '../../signup/screens/register_screen.dart';
import '../cubit/doctor_login_cubit.dart';
import '../cubit/doctor_login_state.dart';
import '../repository/doctor_auth_repository.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    this.initialSnackMessage,
    this.initialSnackSuccess = true,
  });

  final String? initialSnackMessage;
  final bool initialSnackSuccess;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DoctorLoginCubit(const DoctorAuthRepository()),
      child: _LoginView(
        initialSnackMessage: initialSnackMessage,
        initialSnackSuccess: initialSnackSuccess,
      ),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView({this.initialSnackMessage, this.initialSnackSuccess = true});

  final String? initialSnackMessage;
  final bool initialSnackSuccess;

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final msg = widget.initialSnackMessage;
    if (msg != null && msg.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: widget.initialSnackSuccess
                ? AppColors.primary
                : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<DoctorLoginCubit>().login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isValidHospitalBaseUrl = ApiClient.isValidBaseUrlForRole(
      UserRole.hospital,
      ApiConstants.hospitalBaseUrl,
    );

    return BlocConsumer<DoctorLoginCubit, DoctorLoginState>(
      listener: (context, state) {
        if (state is DoctorLoginSuccess) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
        if (state is DoctorLoginFailure) {
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
        final isLoading = state is DoctorLoginLoading;

        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF15192E),
                  AppColors.primary,
                  Color(0xFF2A3150),
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 40,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: AppSpacing.sm),
                          _LoginHeader(
                            onLongPressLogo: () {
                              showAdminLoginDialog(context);
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                            builder: (context, value, child) => Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, (1 - value) * 16),
                                child: child,
                              ),
                            ),
                            child: _LoginFormCard(
                              formKey: _formKey,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              isLoading: isLoading,
                              isValidHospitalBaseUrl: isValidHospitalBaseUrl,
                              onSubmit: _submit,
                              onForgotPassword: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              onRegister: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader({required this.onLongPressLogo});

  final VoidCallback onLongPressLogo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Bounce(
          onLongPress: (_) => onLongPressLogo(),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Image.asset(
              AppImages.logoWithoutBack,
              width: 72,
              height: 72,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'ICU Connect',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppTexts.welcomeBack,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.82),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Sign in to manage admissions and patient care.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.62),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  const _LoginFormCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.isValidHospitalBaseUrl,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onRegister,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final bool isValidHospitalBaseUrl;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppTexts.login, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Enter your credentials to continue.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: emailController,
              hintText: AppTexts.emailLabel,
              prefixIcon: const Icon(Icons.email_outlined),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !isLoading,
              autofillHints: const [AutofillHints.email],
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return AppTexts.emailRequired;
                if (!v.contains('@')) return AppTexts.emailInvalid;
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: passwordController,
              hintText: AppTexts.passwordLabel,
              prefixIcon: const Icon(Icons.lock_outline),
              isPassword: true,
              textInputAction: TextInputAction.done,
              enabled: !isLoading,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => onSubmit(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppTexts.passwordRequired;
                }
                return null;
              },
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: isLoading ? null : onForgotPassword,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  AppTexts.forgotPassword,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            if (!isValidHospitalBaseUrl) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.25),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hospital base URL is not configured correctly.',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 8),
            AppButton(
              label: AppTexts.login,
              onPressed: isLoading || !isValidHospitalBaseUrl ? null : onSubmit,
              isLoading: isLoading,
              borderRadius: 14,
            ),
            const SizedBox(height: 18),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  const Text(
                    "Don't have an account?",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  TextButton(
                    onPressed: isLoading || !isValidHospitalBaseUrl
                        ? null
                        : onRegister,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      AppTexts.createNewAccount,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
