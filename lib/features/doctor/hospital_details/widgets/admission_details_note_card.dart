import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/features/superAdmin/patients/models/patient_admission_models.dart';

import 'admission_details_formatters.dart';
import 'admission_details_type_badge.dart';

class AdmissionDetailsNoteCard extends StatelessWidget {
  const AdmissionDetailsNoteCard({
    super.key,
    required this.note,
    required this.onDelete,
  });

  final ClinicalNoteModel note;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
            children: [
              AdmissionDetailsTypeBadge(type: note.type),
              const Spacer(),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note.content,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            admissionDetailsFormatDateTime(note.createdAt),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
