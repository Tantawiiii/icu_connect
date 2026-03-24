import 'package:bounce/bounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icu_connect/core/constants/app_images.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/network/api_client.dart';
import 'package:icu_connect/core/network/api_constants.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/app_text_field.dart';

import '../../../../superAdmin/login/widgets/admin_login_dialog.dart';
import '../../../home/screens/main_screen.dart';

import '../cubit/doctor_login_cubit.dart';
import '../cubit/doctor_login_state.dart';
import '../repository/doctor_auth_repository.dart';
import '../../signup/screens/register_screen.dart';
import '../../forgetPass/forgot/screens/forgot_password_screen.dart';

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
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Bounce(
                      onLongPress: (_) => showAdminLoginDialog(context),
                      child: Image.asset(
                        AppImages.logoWithoutBack,
                        width: 150,
                        height: 150,
                      ),
                    ),
                    const SizedBox(height: 80),
                    AppTextField(
                      controller: _emailController,
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
                    const SizedBox(height: 20),
                    AppTextField(
                      controller: _passwordController,
                      hintText: AppTexts.passwordLabel,
                      prefixIcon: const Icon(Icons.lock_outline),
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      enabled: !isLoading,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
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
                        onPressed: isLoading
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                );
                              },
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
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.error.withAlpha(77),
                          ),
                        ),
                        child: const Text(
                          'Hospital base URL is not configured correctly.',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                    AppButton(
                      label: AppTexts.login,
                      onPressed: isLoading || !isValidHospitalBaseUrl
                          ? null
                          : _submit,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: isLoading || !isValidHospitalBaseUrl
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                      child: const Text(
                        AppTexts.createNewAccount,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
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
