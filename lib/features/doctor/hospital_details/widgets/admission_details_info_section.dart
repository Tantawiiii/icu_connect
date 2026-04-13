import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/app_text_field.dart';
import 'package:icu_connect/features/superAdmin/patients/models/patient_admission_models.dart';

import '../enums/admission_status.dart';
import 'admission_details_formatters.dart';
import 'admission_details_meta_chip.dart';
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
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    if (!editing) {
      return AdmissionDetailsSectionContainer(
        title: 'Admission Info',
        child: Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            AdmissionDetailsMetaChip(
              label: 'Bed',
              value: admission.bedNumber.isEmpty ? AppTexts.notAvailable : admission.bedNumber,
              icon: Icons.bed_outlined,
            ),
            AdmissionDetailsMetaChip(
              label: 'Status',
              value: admission.status.isEmpty ? AppTexts.notAvailable : admission.status,
              icon: Icons.info_outline,
            ),
            AdmissionDetailsMetaChip(
              label: AppTexts.admitted,
              value: admissionDetailsFormatDate(admission.dateComes),
              icon: Icons.login,
            ),
            AdmissionDetailsMetaChip(
              label: AppTexts.dischargedLabel,
              value: admissionDetailsFormatDate(admission.dateLeave),
              icon: Icons.logout,
            ),
            if (admission.dateOfDeath != null)
              AdmissionDetailsMetaChip(
                label: AppTexts.dateOfDeathLabel,
                value: admissionDetailsFormatDate(admission.dateOfDeath),
                icon: Icons.close,
                color: Colors.red,
              ),
            AdmissionDetailsMetaChip(
              label: 'Notes',
              value: admission.notes.isEmpty ? AppTexts.notAvailable : admission.notes,
              icon: Icons.description_outlined,
            ),
          ],
        ),
      );
    }

    return AdmissionDetailsSectionContainer(
      title: 'Edit Admission Info',
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: bedCtrl!,
              hintText: 'Bed Number',
              validator: (v) => (v?.trim() ?? '').isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<AdmissionStatus>(
              value: editStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              items: AdmissionStatus.values
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.label.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: saving ? null : onStatusChanged,
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Admission date', style: TextStyle(fontSize: 13)),
              subtitle: Text(
                editDateComes != null
                    ? admissionDetailsSqlDateTime(editDateComes!)
                    : AppTexts.notAvailable,
              ),
              leading: const Icon(Icons.event, size: 20),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Leave date', style: TextStyle(fontSize: 13)),
              subtitle: Text(
                editDateLeave != null
                    ? admissionDetailsSqlDateTime(editDateLeave!)
                    : 'Not set',
              ),
              leading: const Icon(Icons.event_available, size: 20),
              trailing: editDateLeave != null
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: saving ? null : onClearDateLeave,
                    )
                  : null,
              onTap: saving ? null : onPickDateLeave,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date of death', style: TextStyle(fontSize: 13)),
              subtitle: Text(
                editDateOfDeath != null
                    ? admissionDetailsSqlDateTime(editDateOfDeath!)
                    : 'Not set',
              ),
              leading: const Icon(Icons.event_busy, size: 20),
              trailing: editDateOfDeath != null
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: saving ? null : onClearDateOfDeath,
                    )
                  : null,
              onTap: saving ? null : onPickDateOfDeath,
            ),
            const SizedBox(height: 6),
            AppTextField(
              controller: notesCtrl!,
              hintText: 'Notes (optional)',
              maxLines: 3,
            ),
            const SizedBox(height: 14),
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
                    label: saving ? '…' : 'Save',
                    height: 48,
                    onPressed: saving ? null : onSave,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
