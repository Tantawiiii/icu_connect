import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';

/// AppBar trailing actions for the admission details screen: AI assistant
/// shortcut, PDF export, and an overflow menu (activity history / export /
/// edit patient / delete admission).
class AdmissionDetailsAppBarActions extends StatelessWidget {
  const AdmissionDetailsAppBarActions({
    super.key,
    required this.exportingPdf,
    required this.exitingAdmission,
    required this.canEditPatient,
    required this.canExit,
    required this.onOpenAiAssistant,
    required this.onExportPdf,
    required this.onActivityHistory,
    required this.onEditPatient,
    required this.onExit,
  });

  final bool exportingPdf;
  final bool exitingAdmission;
  final bool canEditPatient;
  final bool canExit;
  final VoidCallback onOpenAiAssistant;
  final VoidCallback onExportPdf;
  final VoidCallback onActivityHistory;
  final VoidCallback onEditPatient;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: AppTexts.aiClinicalAssistant,
          onPressed: onOpenAiAssistant,
          icon: const Icon(Icons.auto_awesome, color: AppColors.primary),
        ),
        IconButton(
          tooltip: AppTexts.exportAdmissionPdf,
          onPressed: exportingPdf ? null : onExportPdf,
          icon: exportingPdf
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: AppColors.primary,
                ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
          onSelected: (val) {
            switch (val) {
              case 'activity_history':
                onActivityHistory();
              case 'export_pdf':
                onExportPdf();
              case 'edit_patient':
                onEditPatient();
              case 'exit':
                onExit();
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'activity_history',
              child: Text(AppTexts.activityHistorySection),
            ),
            PopupMenuItem(
              value: 'export_pdf',
              enabled: !exportingPdf,
              child: Text(AppTexts.exportAdmissionPdf),
            ),
            if (canEditPatient)
              PopupMenuItem(
                value: 'edit_patient',
                child: Text(AppTexts.editPatientAdmin),
              ),
            if (canExit)
              PopupMenuItem(
                value: 'exit',
                enabled: !exitingAdmission,
                child: Text(
                  exitingAdmission ? 'Deleting…' : 'Delete',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
