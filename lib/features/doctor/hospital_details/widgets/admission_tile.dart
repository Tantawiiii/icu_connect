import 'package:bounce/bounce.dart';
import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';

import '../../../superAdmin/patients/models/patient_admission_models.dart';

class AdmissionTile extends StatelessWidget {
  const AdmissionTile({
    super.key,
    required this.admission,
    required this.onTap,
    required this.formatIsoDateTime,
  });

  final PatientAdmissionModel admission;
  final VoidCallback onTap;
  final String Function(String raw) formatIsoDateTime;

  @override
  Widget build(BuildContext context) {
    final patientName = admission.patient?.name.trim();
    final title = (patientName != null && patientName.isNotEmpty)
        ? patientName
        : AppTexts.admissionCardTitle(
            admission.id,
            admission.bedNumber.isEmpty ? admission.status : admission.bedNumber,
          );

    final subtitleParts = <String>[
      if (admission.bedNumber.isNotEmpty) 'Bed ${admission.bedNumber}',
      if ((admission.dateComes ?? '').isNotEmpty)
        formatIsoDateTime(admission.dateComes!),
    ];

    return Bounce(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_hospital_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitleParts.isEmpty
                        ? AppTexts.notAvailable
                        : subtitleParts.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                admission.status.isEmpty ? AppTexts.notAvailable : admission.status,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

