import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/features/superAdmin/patients/models/patient_admission_models.dart';

import 'admission_details_consultation_card.dart';
import 'admission_details_empty_hint.dart';
import 'admission_details_section_container.dart';

/// "Consultations" section: add form (speciality/reply) plus the list of
/// existing consultations, each editable in place.
///
/// Extracted out of [AdmissionDetailsScreen] to keep that file focused on
/// state/orchestration rather than section layout.
class AdmissionDetailsConsultationsSection extends StatelessWidget {
  const AdmissionDetailsConsultationsSection({
    super.key,
    required this.consultations,
    required this.adding,
    required this.editingItemId,
    required this.onStartAdd,
    required this.addForm,
    required this.editForm,
    required this.onBeginEdit,
    required this.onDelete,
  });

  final List<ConsultationModel> consultations;
  final bool adding;
  final int? editingItemId;
  final VoidCallback onStartAdd;
  final Widget addForm;
  final Widget editForm;
  final void Function(ConsultationModel consultation) onBeginEdit;
  final void Function(int id) onDelete;

  @override
  Widget build(BuildContext context) {
    return AdmissionDetailsSectionContainer(
      title: 'Consultations',
      headerAction: adding || editingItemId != null
          ? null
          : IconButton(
              icon: const Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
                size: 20,
              ),
              onPressed: onStartAdd,
            ),
      child: Column(
        children: [
          if (adding) addForm,
          if (consultations.isEmpty && !adding)
            const AdmissionDetailsEmptyHint('No consultations recorded.')
          else
            ...consultations.map((c) {
              if (editingItemId == c.id) return editForm;
              return AdmissionDetailsConsultationCard(
                consultation: c,
                onEdit: () => onBeginEdit(c),
                onDelete: () => onDelete(c.id),
              );
            }),
        ],
      ),
    );
  }
}
