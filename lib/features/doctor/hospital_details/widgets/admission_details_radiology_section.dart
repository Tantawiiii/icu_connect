import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/features/superAdmin/patients/models/patient_admission_models.dart';

import 'admission_details_empty_hint.dart';
import 'admission_details_radiology_card.dart';
import 'admission_details_section_container.dart';

/// "Radiology" section: add form (title/report/media) plus a horizontal list
/// of existing records, each editable in place.
///
/// Extracted out of [AdmissionDetailsScreen] to keep that file focused on
/// state/orchestration rather than section layout.
class AdmissionDetailsRadiologySection extends StatelessWidget {
  const AdmissionDetailsRadiologySection({
    super.key,
    required this.editingImages,
    required this.nonEditingImages,
    required this.adding,
    required this.headerActionVisible,
    required this.onStartAdd,
    required this.addForm,
    required this.editForm,
    required this.onBeginEdit,
    required this.onDelete,
  });

  final List<RadiologyImageModel> editingImages;
  final List<RadiologyImageModel> nonEditingImages;
  final bool adding;
  final bool headerActionVisible;
  final VoidCallback onStartAdd;
  final Widget addForm;
  final Widget editForm;
  final void Function(RadiologyImageModel image) onBeginEdit;
  final void Function(int id) onDelete;

  @override
  Widget build(BuildContext context) {
    final isEmpty = editingImages.isEmpty && nonEditingImages.isEmpty;

    return AdmissionDetailsSectionContainer(
      title: 'Radiology',
      headerAction: headerActionVisible
          ? IconButton(
              icon: const Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
                size: 20,
              ),
              onPressed: onStartAdd,
            )
          : null,
      child: Column(
        children: [
          if (adding) addForm,
          if (isEmpty && !adding)
            const AdmissionDetailsEmptyHint('No radiology images recorded.')
          else ...[
            ...editingImages.map((_) => editForm),
            if (nonEditingImages.isNotEmpty)
              SizedBox(
                height: 280,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: nonEditingImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 0),
                  itemBuilder: (context, index) {
                    final img = nonEditingImages[index];
                    return AdmissionDetailsRadiologyCard(
                      image: img,
                      compact: true,
                      onEdit: () => onBeginEdit(img),
                      onDelete: () => onDelete(img.id),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}
