import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/app_text_field.dart';
import 'package:icu_connect/features/superAdmin/patients/models/patient_admission_models.dart';

import '../enums/admission_status.dart';
import '../utils/admission_update_validation.dart';
import 'admission_details_formatters.dart';
import 'admission_details_section_container.dart';

class AdmissionDetailsInfoSection extends StatelessWidget {
  const AdmissionDetailsInfoSection({
    super.key,
    required this.admission,
    required this.editing,
    required this.saving,
    required this.formKey,
    required this.bedCtrl,
    required this.notesCtrl,
    required this.editStatus,
    required this.editDateComes,
    required this.editDateLeave,
    required this.editDateOfDeath,
    required this.onStatusChanged,
    required this.onPickDateLeave,
    required this.onClearDateLeave,
    required this.onPickDateOfDeath,
    required this.onClearDateOfDeath,
    required this.onBeginEdit,
    required this.onCancel,
    required this.onSave,
  });

  final PatientAdmissionModel admission;
  final bool editing;
  final bool saving;
  final GlobalKey<FormState> formKey;
  final TextEditingController? bedCtrl;
  final TextEditingController? notesCtrl;
  final AdmissionStatus editStatus;
  final DateTime? editDateComes;
  final DateTime? editDateLeave;
  final DateTime? editDateOfDeath;
  final void Function(AdmissionStatus?) onStatusChanged;
  final VoidCallback onPickDateLeave;
  final VoidCallback onClearDateLeave;
  final VoidCallback onPickDateOfDeath;
  final VoidCallback onClearDateOfDeath;
  final VoidCallback onBeginEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return AdmissionDetailsSectionContainer(
      title: AppTexts.status,
      headerAction: editing
          ? null
          : IconButton(
              tooltip: AppTexts.editAdmission,
              onPressed: onBeginEdit,
              icon: const Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
      child: editing ? _buildEditing(context) : _buildStatusOnly(),
    );
  }

  Widget _buildStatusOnly() {
    final status = admission.status.isEmpty
        ? AppTexts.notAvailable
        : admissionStatusDisplayLabel(admission.status);
    final color = admissionDetailsStatusColor(admission.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: color),
          const SizedBox(width: 10),
          Text(
            status,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditing(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<AdmissionStatus>(
            value: editStatus,
            decoration: const InputDecoration(
              labelText: AppTexts.status,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            items: AdmissionStatus.editable
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.displayLabel),
                  ),
                )
                .toList(),
            onChanged: saving ? null : onStatusChanged,
          ),
          const SizedBox(height: 10),
          AppTextField(
            controller: bedCtrl!,
            hintText: 'Bed Number',
            validator: AdmissionUpdateValidation.bedNumber,
          ),
          const SizedBox(height: 8),
          _CompactDateRow(
            label: AppTexts.admitted,
            value: editDateComes != null
                ? admissionDetailsSqlDateTime(editDateComes!)
                : AppTexts.notAvailable,
            icon: Icons.login,
            editable: false,
          ),
          _CompactDateRow(
            label: AppTexts.dischargedLabel,
            value: editDateLeave != null
                ? admissionDetailsSqlDateTime(editDateLeave!)
                : 'Not set',
            icon: Icons.logout,
            editable: !saving,
            onTap: onPickDateLeave,
            onClear: editDateLeave != null ? onClearDateLeave : null,
          ),
          _CompactDateRow(
            label: AppTexts.dateOfDeathLabel,
            value: editDateOfDeath != null
                ? admissionDetailsSqlDateTime(editDateOfDeath!)
                : 'Not set',
            icon: Icons.event_busy,
            editable: !saving,
            onTap: onPickDateOfDeath,
            onClear: editDateOfDeath != null ? onClearDateOfDeath : null,
          ),
          const SizedBox(height: 8),
          AppTextField(
            controller: notesCtrl!,
            hintText: 'Notes (optional)',
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: saving ? null : onCancel,
                  child: Text(AppTexts.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: saving ? '…' : AppTexts.save,
                  height: 44,
                  onPressed: saving ? null : onSave,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactDateRow extends StatelessWidget {
  const _CompactDateRow({
    required this.label,
    required this.value,
    required this.icon,
    this.editable = false,
    this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool editable;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: editable ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClear != null && editable)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close, size: 16),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
