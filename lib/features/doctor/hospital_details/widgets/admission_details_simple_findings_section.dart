import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';

import 'admission_details_empty_hint.dart';
import 'admission_details_section_container.dart';
import 'admission_details_simple_text_card.dart';

/// A single free-text finding (echo, ultrasound, ...) rendered by
/// [AdmissionDetailsSimpleFindingsSection].
class SimpleFindingItem {
  const SimpleFindingItem({
    required this.id,
    required this.text,
    required this.createdAt,
  });

  final int id;
  final String text;
  final String createdAt;
}

/// Shared "add one free-text note, list existing ones" section used for
/// record types that only carry a single text field (echo, ultrasound, ...).
///
/// Consolidates what used to be near-identical inline sections duplicated in
/// [AdmissionDetailsScreen] for each of these record types.
class AdmissionDetailsSimpleFindingsSection extends StatelessWidget {
  const AdmissionDetailsSimpleFindingsSection({
    super.key,
    required this.title,
    required this.emptyHint,
    required this.items,
    required this.adding,
    required this.editingItemId,
    required this.onStartAdd,
    required this.addForm,
    required this.editForm,
    required this.onBeginEdit,
    required this.onDelete,
  });

  final String title;
  final String emptyHint;
  final List<SimpleFindingItem> items;
  final bool adding;
  final int? editingItemId;
  final VoidCallback onStartAdd;
  final Widget addForm;
  final Widget editForm;
  final void Function(SimpleFindingItem item) onBeginEdit;
  final void Function(int id) onDelete;

  @override
  Widget build(BuildContext context) {
    return AdmissionDetailsSectionContainer(
      title: title,
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
          if (items.isEmpty && !adding)
            AdmissionDetailsEmptyHint(emptyHint)
          else
            ...items.map((item) {
              if (editingItemId == item.id) return editForm;
              return AdmissionDetailsSimpleTextCard(
                text: item.text,
                date: item.createdAt,
                onEdit: () => onBeginEdit(item),
                onDelete: () => onDelete(item.id),
              );
            }),
        ],
      ),
    );
  }
}
