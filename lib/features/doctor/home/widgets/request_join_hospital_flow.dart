import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/features/doctor/home/cubit/doctor_hospitals_cubit.dart';
import 'package:icu_connect/features/doctor/home/models/doctor_hospital.dart';
import 'package:icu_connect/features/doctor/profile/repository/doctor_profile_repository.dart';


Future<void> showJoinHospitalRequestFlow(
  BuildContext context,
  DoctorHospital hospital,
) async {
  final rootContext = context;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    isDismissible: true,
    enableDrag: true,
    builder: (sheetContext) => _JoinHospitalRequestSheet(
      hospital: hospital,
      rootContext: rootContext,
    ),
  );
}

class _JoinHospitalRequestSheet extends StatefulWidget {
  const _JoinHospitalRequestSheet({
    required this.hospital,
    required this.rootContext,
  });

  final DoctorHospital hospital;
  final BuildContext rootContext;

  @override
  State<_JoinHospitalRequestSheet> createState() => _JoinHospitalRequestSheetState();
}

class _JoinHospitalRequestSheetState extends State<_JoinHospitalRequestSheet> {
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      const repo = DoctorProfileRepository();
      final profile = await repo.fetchProfile();
      final ids = profile.hospitals.map((h) => h.id).toSet()..add(widget.hospital.id);
      await repo.updateProfile(
        name: profile.name,
        email: profile.email,
        phone: profile.phone,
        hospitalIds: ids.toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      if (!widget.rootContext.mounted) return;
      ScaffoldMessenger.of(widget.rootContext).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.textInverse,
                size: 22,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppTexts.hospitalJoinRequestSent,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
        ),
      );
      await widget.rootContext.read<DoctorHospitalsCubit>().refresh();
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (!widget.rootContext.mounted) return;
      ScaffoldMessenger.of(widget.rootContext).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (!widget.rootContext.mounted) return;
      ScaffoldMessenger.of(widget.rootContext).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          content: const Text(AppTexts.hospitalJoinRequestFailed),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_loading,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 32,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.accent.withValues(alpha: 0.18),
                            AppColors.primary.withValues(alpha: 0.1),
                          ],
                        ),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(
                        Icons.domain_add_rounded,
                        size: 36,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppTexts.hospitalJoinRequestTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.hospital.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    AppTexts.hospitalJoinRequestMessage,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textInverse,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      AppTexts.sendJoinRequest,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      AppTexts.cancel,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            if (_loading)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: ColoredBox(
                  color: AppColors.surface.withValues(alpha: 0.92),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.accent,
                          backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppTexts.joinRequestSending,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
