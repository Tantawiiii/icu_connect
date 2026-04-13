import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/widgets/app_button.dart';

import '../models/hospital_doctor.dart';

class DoctorCard extends StatelessWidget {
  const DoctorCard({
    super.key,
    required this.doctor,
    required this.isAdmin,
    required this.accepting,
    required this.activating,
    required this.onAccept,
    required this.onActivate,
  });

  final HospitalDoctor doctor;
  final bool isAdmin;
  final bool accepting;
  final bool activating;
  final VoidCallback onAccept;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final status = (doctor.status ?? '').toLowerCase();
    final canAccept = isAdmin && status == 'pending';
    final canActivate = isAdmin && !doctor.isActive;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              doctor.name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              doctor.email,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              doctor.phone,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 2,
              children: [
                Chip(
                  label: Text('Role: ${doctor.roleInHospital ?? doctor.role}'),
                ),
                Chip(
                  label: Text(
                    'Status: ${doctor.status ?? AppTexts.notAvailable}',
                  ),
                ),
                Chip(
                  label: Text(
                    doctor.isActive ? AppTexts.active : AppTexts.inactive,
                  ),
                ),
              ],
            ),
            if (canAccept || canActivate) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (canAccept)
                    Expanded(
                      child: AppButton(
                        label: AppTexts.acceptDoctor,
                        height: 42,
                        isLoading: accepting,
                        onPressed: accepting ? null : onAccept,
                      ),
                    ),
                  if (canAccept && canActivate) const SizedBox(width: 10),
                  if (canActivate)
                    Expanded(
                      child: AppButton(
                        label: AppTexts.activateDoctor,
                        height: 42,
                        isLoading: activating,
                        onPressed: activating ? null : onActivate,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
