import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/app_text_field.dart';
import 'package:icu_connect/features/superAdmin/patients/models/patient_admission_models.dart';

import 'admission_details_formatters.dart';
import 'admission_details_meta_chip.dart';

class AdmissionDetailsPatientHeaderSection extends StatelessWidget {
  const AdmissionDetailsPatientHeaderSection({
    super.key,
    required this.admission,
    required this.editing,
    required this.saving,
    required this.formKey,
    required this.nameCtrl,
    required this.nationalIdCtrl,
    required this.ageCtrl,
    required this.phoneCtrl,
    required this.notesCtrl,
    required this.gender,
    required this.bloodGroup,
    required this.genders,
    required this.bloodGroups,
    required this.onGenderChanged,
    required this.onBloodGroupChanged,
    required this.onBeginEdit,
    required this.onCancel,
    required this.onSave,
  });

  final PatientAdmissionModel admission;
  final bool editing;
  final bool saving;
  final GlobalKey<FormState> formKey;
  final TextEditingController? nameCtrl;
  final TextEditingController? nationalIdCtrl;
  final TextEditingController? ageCtrl;
  final TextEditingController? phoneCtrl;
  final TextEditingController? notesCtrl;
  final String gender;
  final String? bloodGroup;
  final List<String> genders;
  final List<String> bloodGroups;
  final void Function(String?) onGenderChanged;
  final void Function(String?) onBloodGroupChanged;
  final VoidCallback? onBeginEdit;
  final VoidCallback? onSave;
  final VoidCallback onCancel;

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  List<Widget> _patientMetaChips(AdmissionPatientModel? patient) {
    final chips = <Widget>[];

    if (admission.dateComes != null && admission.dateComes!.trim().isNotEmpty) {
      chips.add(
        AdmissionDetailsMetaChip(
          label: AppTexts.admitted,
          value: admissionDetailsFormatDate(admission.dateComes),
          icon: Icons.login,
        ),
      );
    }

    if (patient != null) {
      chips.add(
        AdmissionDetailsMetaChip(
          label: AppTexts.age,
          value: '${patient.age}',
          icon: Icons.cake,
        ),
      );

      if (_hasText(patient.gender)) {
        chips.add(
          AdmissionDetailsMetaChip(
            label: AppTexts.gender,
            value: patient.gender,
            icon: Icons.person_outline,
          ),
        );
      }

      if (_hasText(patient.bloodGroup)) {
        chips.add(
          AdmissionDetailsMetaChip(
            label: AppTexts.bloodGroup,
            value: patient.bloodGroup,
            icon: Icons.bloodtype,
          ),
        );
      }

      if (_hasText(patient.phone)) {
        chips.add(
          AdmissionDetailsMetaChip(
            label: AppTexts.phone,
            value: patient.phone,
            icon: Icons.phone,
          ),
        );
      }

      if (_hasText(patient.nationalId)) {
        chips.add(
          AdmissionDetailsMetaChip(
            label: AppTexts.nationalId,
            value: patient.nationalId,
            icon: Icons.badge,
          ),
        );
      }
    }

    if (admission.dateLeave != null && admission.dateLeave!.trim().isNotEmpty) {
      chips.add(
        AdmissionDetailsMetaChip(
          label: AppTexts.dischargedLabel,
          value: admissionDetailsFormatDate(admission.dateLeave),
          icon: Icons.logout,
        ),
      );
    }

    if (admission.dateOfDeath != null &&
        admission.dateOfDeath!.trim().isNotEmpty) {
      chips.add(
        AdmissionDetailsMetaChip(
          label: AppTexts.dateOfDeathLabel,
          value: admissionDetailsFormatDate(admission.dateOfDeath),
          icon: Icons.close,
          color: Colors.red,
        ),
      );
    }

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final patient = admission.patient;
    final metaChips = _patientMetaChips(patient);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                admission.bedNumber.isEmpty
                    ? AppTexts.notAvailable
                    : admission.bedNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const Spacer(),
            if (!editing && patient != null && onBeginEdit != null)
              IconButton(
                tooltip: AppTexts.editPatientAdmin,
                onPressed: onBeginEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
              )
            else if (editing)
              const Text(
                'Edit Patient',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (editing && nameCtrl != null)
          Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: nameCtrl!,
                  hintText: AppTexts.name,
                  validator: (v) =>
                      (v?.trim() ?? '').isEmpty ? AppTexts.nameRequired : null,
                  inputFormatters: [LengthLimitingTextInputFormatter(255)],
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: nationalIdCtrl!,
                  hintText: AppTexts.nationalId,
                  validator: (v) => (v?.trim() ?? '').isEmpty
                      ? 'National ID is required'
                      : null,
                  inputFormatters: [LengthLimitingTextInputFormatter(50)],
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: ageCtrl!,
                  hintText: AppTexts.age,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return 'Age is required';
                    final n = int.tryParse(t);
                    if (n == null || n < 0 || n > 150) {
                      return 'Enter a valid age';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: gender,
                  decoration: const InputDecoration(
                    labelText: AppTexts.gender,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  items: genders
                      .map(
                        (g) => DropdownMenuItem(
                          value: g,
                          child: Text(g[0].toUpperCase() + g.substring(1)),
                        ),
                      )
                      .toList(),
                  onChanged: saving ? null : onGenderChanged,
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: phoneCtrl!,
                  hintText: '${AppTexts.phone} (optional)',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [LengthLimitingTextInputFormatter(20)],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  value: bloodGroup,
                  decoration: const InputDecoration(
                    labelText: 'Blood group (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  hint: const Text('Select blood group'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('—'),
                    ),
                    ...bloodGroups.map(
                      (b) =>
                          DropdownMenuItem<String?>(value: b, child: Text(b)),
                    ),
                  ],
                  onChanged: saving ? null : onBloodGroupChanged,
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: notesCtrl!,
                  hintText: '${AppTexts.notes} (optional)',
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
          )
        else if (metaChips.isNotEmpty)
          Wrap(spacing: 16, runSpacing: 4, children: metaChips),
      ],
    );
  }
}
