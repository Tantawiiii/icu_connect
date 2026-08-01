import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/features/superAdmin/patients/models/patient_admission_models.dart';

import 'admission_details_formatters.dart';
import 'admission_details_item_actions.dart';

class AdmissionDetailsMedicationCard extends StatelessWidget {
  const AdmissionDetailsMedicationCard({
    super.key,
    required this.med,
    required this.onEdit,
    required this.onDelete,
  });

  final MedicationModel med;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String? _detailsLine() {
    final parts = <String>[
      if (med.type.trim().isNotEmpty)
        med.type.replaceAll('_', ' '),
      if (med.value.trim().isNotEmpty) med.value.trim(),
      if (med.duration.trim().isNotEmpty) med.duration.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final details = _detailsLine();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    if (details != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        details,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              AdmissionDetailsItemActions(onEdit: onEdit, onDelete: onDelete),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            admissionDetailsFormatDateTime(med.createdAt),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
