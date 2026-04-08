import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_texts.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_constants.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../cubit/doctor_signup_cubit.dart';
import '../cubit/doctor_signup_state.dart';
import '../repository/doctor_signup_repository.dart';
import 'registration_pending_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DoctorSignupCubit(const DoctorSignupRepository())..loadHospitals(),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  /// Full name passed to signup (`first` + space + `last`); kept in sync in [_submit].
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final fullName = last.isEmpty ? first : '$first $last'.trim();
    _nameController.text = fullName;

    context.read<DoctorSignupCubit>().signup(
      name: fullName,
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isValidHospitalBaseUrl = ApiClient.isValidBaseUrlForRole(
      UserRole.hospital,
      ApiConstants.hospitalBaseUrl,
    );

    return BlocConsumer<DoctorSignupCubit, DoctorSignupState>(
      listener: (context, state) {
        if (state is DoctorSignupSuccess) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => RegistrationPendingScreen(
                apiMessage: state.response.message,
                user: state.response.data.user,
              ),
            ),
          );
        }
        if (state is DoctorSignupSignupFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<DoctorSignupCubit>().clearSignupFailure();
        }
      },
      builder: (context, state) {
        final isLoadingHospitals =
            state is DoctorSignupHospitalsLoading ||
            state is DoctorSignupInitial;
        final isSubmitting = state is DoctorSignupSubmitting;
        final isBusy = isLoadingHospitals || isSubmitting;

        final DoctorSignupReady? ready = switch (state) {
          DoctorSignupReady r => r,
          DoctorSignupSubmitting(
            hospitals: final hospitals,
            selectedHospitalId: final selectedHospitalId,
          ) =>
            DoctorSignupReady(
              hospitals: hospitals,
              selectedHospitalId: selectedHospitalId,
            ),
          DoctorSignupSignupFailure(:final recover) => recover,
          _ => null,
        };

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            title: const Text(
              AppTexts.registerTitle,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: switch (state) {
              DoctorSignupHospitalsFailure(:final message) => _HospitalsError(
                message: message,
                onRetry: () =>
                    context.read<DoctorSignupCubit>().loadHospitals(),
              ),
              _ => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 38,),
                      if (!isValidHospitalBaseUrl) ...[
                        Container(
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
                        const SizedBox(height: 16),
                      ],
                      if (isLoadingHospitals)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (ready != null) ...[
                        AppTextField(
                          controller: _firstNameController,
                          labelText: AppTexts.firstName,
                          prefixIcon: const Icon(Icons.person_outline),
                          textInputAction: TextInputAction.next,
                          enabled: !isBusy && isValidHospitalBaseUrl,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return AppTexts.nameRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _lastNameController,
                          labelText: AppTexts.lastName,
                          prefixIcon: const Icon(Icons.badge_outlined),
                          textInputAction: TextInputAction.next,
                          enabled: !isBusy && isValidHospitalBaseUrl,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _emailController,
                          labelText: AppTexts.emailLabel,
                          prefixIcon: const Icon(Icons.email_outlined),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          enabled: !isBusy && isValidHospitalBaseUrl,
                          autofillHints: const [AutofillHints.email],
                          validator: (v) {
                            final t = v?.trim() ?? '';
                            if (t.isEmpty) return AppTexts.emailRequired;
                            if (!t.contains('@')) return AppTexts.emailInvalid;
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _phoneController,
                          labelText: AppTexts.phone,
                          prefixIcon: const Icon(Icons.phone_outlined),
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          enabled: !isBusy && isValidHospitalBaseUrl,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return AppTexts.phoneRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int?>(
                          isExpanded: true,
                          value: ready.selectedHospitalId,
                          decoration: const InputDecoration(
                            labelText: AppTexts.hospitalLabel,
                            prefixIcon: Icon(Icons.local_hospital_outlined),
                          ),
                          selectedItemBuilder: (context) {
                            return [
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  AppTexts.hospitalOtherOptional,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ...ready.hospitals.map((h) {
                                final label =
                                    h.location != null && h.location!.isNotEmpty
                                        ? '${h.name} — ${h.location}'
                                        : h.name;
                                return Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ];
                          },
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text(AppTexts.hospitalOtherOptional),
                            ),
                            ...ready.hospitals.map(
                              (h) => DropdownMenuItem<int?>(
                                value: h.id,
                                child: Text(
                                  h.location != null && h.location!.isNotEmpty
                                      ? '${h.name} — ${h.location}'
                                      : h.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: !isBusy && isValidHospitalBaseUrl
                              ? (id) => context
                                    .read<DoctorSignupCubit>()
                                    .selectHospital(id)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _passwordController,
                          labelText: AppTexts.passwordLabel,
                          prefixIcon: const Icon(Icons.lock_outline),
                          isPassword: true,
                          textInputAction: TextInputAction.next,
                          enabled: !isBusy && isValidHospitalBaseUrl,
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
                          controller: _confirmPasswordController,
                          labelText: AppTexts.confirmPasswordLabel,
                          prefixIcon: const Icon(Icons.lock_outline),
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          enabled: !isBusy && isValidHospitalBaseUrl,
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
                        const SizedBox(height: 28),
                        AppButton(
                          label: AppTexts.register,
                          onPressed:
                              !isValidHospitalBaseUrl || isBusy ? null : _submit,
                          isLoading: isSubmitting,
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            },
          ),
        );
      },
    );
  }
}

class _HospitalsError extends StatelessWidget {
  const _HospitalsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),
            AppButton(label: AppTexts.retry, onPressed: onRetry, width: 160),
          ],
        ),
      ),
    );
  }
}
