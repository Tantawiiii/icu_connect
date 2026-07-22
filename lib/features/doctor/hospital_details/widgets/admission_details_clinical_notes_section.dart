import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/app_text_field.dart';
import 'package:icu_connect/features/superAdmin/patients/models/patient_admission_models.dart';

import '../enums/admission_status.dart';
import 'admission_details_empty_hint.dart';
import 'admission_details_formatters.dart';
import 'admission_details_item_actions.dart';
import 'admission_details_section_container.dart';

class AdmissionDetailsClinicalNotesSection extends StatelessWidget {
  const AdmissionDetailsClinicalNotesSection({
    super.key,
    required this.notes,
    required this.adding,
    required this.editingItemId,
    required this.pendingType,
    required this.saving,
    required this.contentController,
    required this.onStartAdd,
    required this.onCancelAdd,
    required this.onSaveAdd,
    required this.onBeginEdit,
    required this.onCancelEdit,
    required this.onSaveEdit,
    required this.onDelete,
  });

  final List<ClinicalNoteModel> notes;
  final bool adding;
  final int? editingItemId;
  final String? pendingType;
  final bool saving;
  final TextEditingController contentController;
  final void Function(String type) onStartAdd;
  final VoidCallback onCancelAdd;
  final VoidCallback onSaveAdd;
  final void Function(ClinicalNoteModel note) onBeginEdit;
  final VoidCallback onCancelEdit;
  final VoidCallback onSaveEdit;
  final void Function(int id) onDelete;

  List<ClinicalNoteModel> _notesForType(String type) {
    return notes.where((n) => AdmissionClinicalNoteType.normalize(n.type) == type).toList();
  }

  bool _isAddingType(String type) =>
      adding && AdmissionClinicalNoteType.normalize(pendingType) == type;

  bool _isEditingInType(String type) {
    if (editingItemId == null) return false;
    for (final note in notes) {
      if (note.id == editingItemId &&
          AdmissionClinicalNoteType.normalize(note.type) == type) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < AdmissionClinicalNoteType.values.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _ClinicalNoteTypeCard(
            type: AdmissionClinicalNoteType.values[i],
            notes: _notesForType(AdmissionClinicalNoteType.values[i]),
            showAddForm: _isAddingType(AdmissionClinicalNoteType.values[i]),
            editingItemId: _isEditingInType(AdmissionClinicalNoteType.values[i])
                ? editingItemId
                : null,
            saving: saving,
            contentController: contentController,
            canAdd: !adding && editingItemId == null,
            onAdd: () => onStartAdd(AdmissionClinicalNoteType.values[i]),
            onCancelAdd: onCancelAdd,
            onSaveAdd: onSaveAdd,
            onBeginEdit: onBeginEdit,
            onCancelEdit: onCancelEdit,
            onSaveEdit: onSaveEdit,
            onDelete: onDelete,
          ),
        ],
      ],
    );
  }
}

class _ClinicalNoteTypeCard extends StatelessWidget {
  const _ClinicalNoteTypeCard({
    required this.type,
    required this.notes,
    required this.showAddForm,
    required this.editingItemId,
    required this.saving,
    required this.contentController,
    required this.canAdd,
    required this.onAdd,
    required this.onCancelAdd,
    required this.onSaveAdd,
    required this.onBeginEdit,
    required this.onCancelEdit,
    required this.onSaveEdit,
    required this.onDelete,
  });

  final String type;
  final List<ClinicalNoteModel> notes;
  final bool showAddForm;
  final int? editingItemId;
  final bool saving;
  final TextEditingController contentController;
  final bool canAdd;
  final VoidCallback onAdd;
  final VoidCallback onCancelAdd;
  final VoidCallback onSaveAdd;
  final void Function(ClinicalNoteModel note) onBeginEdit;
  final VoidCallback onCancelEdit;
  final VoidCallback onSaveEdit;
  final void Function(int id) onDelete;

  String get _typeLabel =>
      AdmissionClinicalNoteType.labelFor(type);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
              Expanded(
                child: Text(
                  _typeLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (canAdd)
                IconButton(
                  tooltip: 'Add $_typeLabel',
                  onPressed: onAdd,
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (showAddForm) ...[
            const SizedBox(height: 8),
            _ClinicalNoteForm(
              title: 'Add $_typeLabel',
              saving: saving,
              contentController: contentController,
              onCancel: onCancelAdd,
              onSave: onSaveAdd,
            ),
          ],
          if (notes.isEmpty && !showAddForm)
            AdmissionDetailsEmptyHint('No $_typeLabel recorded.')
          else ...[
            for (final note in notes) ...[
              const SizedBox(height: 8),
              if (editingItemId == note.id)
                _ClinicalNoteForm(
                  title: 'Edit $_typeLabel',
                  isEditing: true,
                  saving: saving,
                  contentController: contentController,
                  onCancel: onCancelEdit,
                  onSave: onSaveEdit,
                )
              else
                _ClinicalNoteEntry(
                  note: note,
                  onEdit: () => onBeginEdit(note),
                  onDelete: () => onDelete(note.id),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ClinicalNoteEntry extends StatelessWidget {
  const _ClinicalNoteEntry({
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  final ClinicalNoteModel note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  note.content,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
              AdmissionDetailsItemActions(onEdit: onEdit, onDelete: onDelete),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            admissionDetailsFormatDateTime(note.createdAt),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicalNoteForm extends StatelessWidget {
  const _ClinicalNoteForm({
    required this.title,
    required this.saving,
    required this.contentController,
    required this.onCancel,
    required this.onSave,
    this.isEditing = false,
  });

  final String title;
  final bool saving;
  final TextEditingController contentController;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: saving ? null : onCancel,
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          AppTextField(
            controller: contentController,
            hintText: 'Content *',
            maxLines: 5,
            enabled: !saving,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: AppButton(
              label: saving
                  ? 'Saving...'
                  : isEditing
                      ? AppTexts.saveChanges
                      : 'Save Entry',
              onPressed: saving ? null : onSave,
            ),
          ),
        ],
      ),
    );
  }
}
