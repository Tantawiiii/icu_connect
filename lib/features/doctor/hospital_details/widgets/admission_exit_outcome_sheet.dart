import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';

import '../enums/admission_status.dart';

class AdmissionExitOutcomeSheet extends StatelessWidget {
  const AdmissionExitOutcomeSheet({super.key});

  static final _outcomes = AdmissionStatus.dischargedOutcomes;

  static Future<AdmissionStatus?> show(BuildContext context) {
    return showModalBottomSheet<AdmissionStatus>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AdmissionExitOutcomeSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
            const SizedBox(height: 16),
            const Text(
              'Exit patient',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select the discharge outcome for this admission.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ..._outcomes.map(
              (status) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  tileColor: status.dischargedOutcomeBackground,
                  leading: Icon(
                    _iconFor(status),
                    color: AppColors.textPrimary,
                  ),
                  title: Text(
                    status.dischargedScreenLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(AdmissionStatus status) {
    switch (status) {
      case AdmissionStatus.discharged:
        return Icons.check_circle_outline;
      case AdmissionStatus.deceased:
        return Icons.favorite_border;
      case AdmissionStatus.leavesAma:
        return Icons.exit_to_app;
      default:
        return Icons.logout;
    }
  }
}
