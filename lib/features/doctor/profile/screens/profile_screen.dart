import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
import '../../session/doctor_session_display.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../cubit/doctor_profile_cubit.dart';
import '../cubit/doctor_profile_state.dart';
import '../models/doctor_profile.dart';
import '../repository/doctor_profile_repository.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DoctorProfileCubit(const DoctorProfileRepository())..load(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _lastSyncedUpdatedAt;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _syncControllersFromProfile(DoctorProfile profile) {
    if (_lastSyncedUpdatedAt == profile.updatedAt) return;
    _lastSyncedUpdatedAt = profile.updatedAt;
    _nameController.text = profile.name;
    _emailController.text = profile.email;
    _phoneController.text = profile.phone;
    _passwordController.clear();
    _confirmPasswordController.clear();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<DoctorProfileCubit>();
    final state = cubit.state;
    if (state is! DoctorProfileReady) return;
    if (state.hospitalIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppTexts.profileMinOneHospital),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    cubit.save(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DoctorProfileCubit, DoctorProfileState>(
      listenWhen: (prev, next) =>
          next is DoctorProfileSaveFailure ||
          (next is DoctorProfileReady &&
              prev is DoctorProfileReady &&
              prev.isSaving &&
              !next.isSaving),
      listener: (context, state) {
        if (state is DoctorProfileSaveFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<DoctorProfileCubit>().clearSaveFailure();
        } else if (state is DoctorProfileReady && !state.isSaving) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppTexts.profileUpdateSuccess),
              behavior: SnackBarBehavior.floating,
            ),
          );
          DoctorSessionDisplay.apply(
            name: state.profile.name,
            role: state.profile.role,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            title: const Text(
              AppTexts.profileScreenTitle,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: switch (state) {
            DoctorProfileInitial() || DoctorProfileLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            DoctorProfileLoadFailure(:final message) => _LoadError(
                message: message,
                onRetry: () => context.read<DoctorProfileCubit>().load(),
              ),
            final DoctorProfileReady ready =>
              _buildReadyBody(context, ready),
            DoctorProfileSaveFailure(:final recover) =>
              _buildReadyBody(context, recover),
          },
        );
      },
    );
  }

  Widget _buildReadyBody(BuildContext context, DoctorProfileReady ready) {
    _syncControllersFromProfile(ready.profile);
    return _buildForm(context, ready);
  }

  Widget _buildForm(BuildContext context, DoctorProfileReady ready) {
    final busy = ready.isSaving;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(profile: ready.profile),
            const SizedBox(height: 28),
            Text(
              AppTexts.profileAccountSection,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _nameController,
              labelText: AppTexts.name,
              prefixIcon: const Icon(Icons.person_outline),
              textInputAction: TextInputAction.next,
              enabled: !busy,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return AppTexts.nameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _emailController,
              labelText: AppTexts.emailLabel,
              prefixIcon: const Icon(Icons.email_outlined),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !busy,
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
              enabled: !busy,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return AppTexts.phoneRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _passwordController,
              labelText: AppTexts.passwordOptionalHint,
              prefixIcon: const Icon(Icons.lock_outline),
              isPassword: true,
              textInputAction: TextInputAction.next,
              enabled: !busy,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _confirmPasswordController,
              labelText: AppTexts.confirmPasswordLabel,
              prefixIcon: const Icon(Icons.lock_outline),
              isPassword: true,
              textInputAction: TextInputAction.done,
              enabled: !busy,
              onFieldSubmitted: (_) => _submit(),
              validator: (v) {
                final p = _passwordController.text;
                if (p.isEmpty) return null;
                if (v == null || v.isEmpty) {
                  return AppTexts.confirmPasswordRequired;
                }
                if (v != p) return AppTexts.passwordsDoNotMatch;
                return null;
              },
            ),
            const SizedBox(height: 28),
            Text(
              AppTexts.profileHospitalsSection,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              AppTexts.profileJoinHospitalHint,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 12),
            _HospitalChips(ready: ready),
            const SizedBox(height: 12),
            _AddHospitalDropdown(ready: ready, enabled: !busy),
            const SizedBox(height: 32),
            AppButton(
              label: AppTexts.save,
              onPressed: busy ? null : _submit,
              isLoading: busy,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final DoctorProfile profile;

  String get _initials {
    final parts = profile.name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts[0];
      return s.isNotEmpty ? s[0].toUpperCase() : '?';
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String? _shortDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final i = iso.indexOf('T');
    return i > 0 ? iso.substring(0, i) : iso;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.primary,
          child: Text(
            _initials,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          profile.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            Chip(
              label: Text(
                profile.role.toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppColors.accent.withValues(alpha: 0.12),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            Chip(
              label: Text(
                profile.isActive ? AppTexts.active : AppTexts.inactive,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              backgroundColor: profile.isActive
                  ? AppColors.success.withValues(alpha: 0.15)
                  : AppColors.error.withValues(alpha: 0.12),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ],
        ),
        if (_shortDate(profile.lastLoginAt) != null) ...[
          const SizedBox(height: 10),
          Text(
            '${AppTexts.lastLogin}: ${_shortDate(profile.lastLoginAt)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _HospitalChips extends StatelessWidget {
  const _HospitalChips({required this.ready});

  final DoctorProfileReady ready;

  static String _nameForId(int id, DoctorProfileReady ready) {
    for (final h in ready.profile.hospitals) {
      if (h.id == id) return h.name;
    }
    for (final h in ready.catalogHospitals) {
      if (h.id == id) return h.name;
    }
    return 'Hospital #$id';
  }

  static ProfileHospital? _profileHospital(int id, DoctorProfile profile) {
    for (final h in profile.hospitals) {
      if (h.id == id) return h;
    }
    return null;
  }

  static String? _statusLine(ProfileHospital? h) {
    final st = h?.pivot?.status;
    if (st == null || st.isEmpty) return null;
    return '${AppTexts.status}: $st';
  }

  @override
  Widget build(BuildContext context) {
    if (ready.hospitalIds.isEmpty) {
      return Text(
        AppTexts.profileMinOneHospital,
        style: TextStyle(
          fontSize: 13,
          color: AppColors.warning.withValues(alpha: 0.95),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ready.hospitalIds.map((id) {
        final ph = _profileHospital(id, ready.profile);
        final status = _statusLine(ph);
        return InputChip(
          label: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _nameForId(id, ready),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (status != null)
                  Text(
                    status,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          onDeleted: ready.isSaving
              ? null
              : () => context.read<DoctorProfileCubit>().removeHospitalId(id),
          deleteIconColor: AppColors.textSecondary,
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        );
      }).toList(),
    );
  }
}

class _AddHospitalDropdown extends StatelessWidget {
  const _AddHospitalDropdown({required this.ready, required this.enabled});

  final DoctorProfileReady ready;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final available = ready.catalogHospitals
        .where((h) => !ready.hospitalIds.contains(h.id))
        .toList();

    if (available.isEmpty) {
      return Text(
        ready.catalogHospitals.isEmpty
            ? AppTexts.noHospitalsAvailable
            : AppTexts.profileAllHospitalsInList,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      );
    }

    return DropdownButtonFormField<int>(
      isExpanded: true,
      value: null,
      decoration: const InputDecoration(
        labelText: AppTexts.addHospitalAssignment,
        prefixIcon: Icon(Icons.add_business_outlined),
      ),
      hint: Text(
        AppTexts.selectHospital,
        style: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.85),
        ),
      ),
      items: available
          .map(
            (h) => DropdownMenuItem<int>(
              value: h.id,
              child: Text(
                h.location != null && h.location!.isNotEmpty
                    ? '${h.name} — ${h.location}'
                    : h.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: enabled
          ? (id) {
              if (id != null) {
                context.read<DoctorProfileCubit>().addHospitalId(id);
              }
            }
          : null,
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

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
              Icons.person_off_outlined,
              size: 52,
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
