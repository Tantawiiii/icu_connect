import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/widgets/app_text_field.dart';
import 'package:icu_connect/features/superAdmin/patients/models/patient_admission_models.dart';

import '../enums/admission_status.dart';
import 'admission_details_formatters.dart';
import 'admission_details_meta_chip.dart';
import 'admission_details_section_container.dart';

class AdmissionFormEssentialsSection extends StatelessWidget {
  const AdmissionFormEssentialsSection({
    super.key,
    required this.isEdit,
    required this.submitting,
    required this.bedCtrl,
    required this.status,
    required this.dateComes,
    required this.dateLeave,
    required this.dateOfDeath,
    required this.selectedPatient,
    required this.onStatusChanged,
    required this.onPickDateComes,
    required this.onPickDateLeave,
    required this.onClearDateLeave,
    required this.onPickDateOfDeath,
    required this.onClearDateOfDeath,
    required this.bedValidator,
    required this.patientValidator,
  });

  final bool isEdit;
  final bool submitting;
  final TextEditingController bedCtrl;
  final AdmissionStatus status;
  final DateTime? dateComes;
  final DateTime? dateLeave;
  final DateTime? dateOfDeath;
  final AdmissionPatientModel? selectedPatient;
  final ValueChanged<AdmissionStatus?> onStatusChanged;
  final VoidCallback onPickDateComes;
  final VoidCallback onPickDateLeave;
  final VoidCallback onClearDateLeave;
  final VoidCallback onPickDateOfDeath;
  final VoidCallback onClearDateOfDeath;
  final String? Function(String?)? bedValidator;
  final String? Function(AdmissionPatientModel?)? patientValidator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdmissionDetailsSectionContainer(
          title: AppTexts.patientLabel,
          child: FormField<AdmissionPatientModel>(
            validator: (_) => patientValidator?.call(selectedPatient),
            builder: (field) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PatientSummary(patient: selectedPatient),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        field.errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        // AdmissionDetailsSectionContainer(
        //   title: isEdit ? AppTexts.editAdmission : AppTexts.createAdmission,
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.stretch,
        //     children: [
        //       AppTextField(
        //         controller: bedCtrl,
        //         labelText: AppTexts.bedNo,
        //         hintText: AppTexts.bedNo,
        //         keyboardType: TextInputType.number,
        //         validator: bedValidator,
        //       ),
        //       const SizedBox(height: 12),
        //       if (isEdit)
        //         DropdownButtonFormField<AdmissionStatus>(
        //           value: status,
        //           decoration: const InputDecoration(
        //             labelText: AppTexts.status,
        //             border: OutlineInputBorder(
        //               borderRadius: BorderRadius.all(Radius.circular(12)),
        //             ),
        //           ),
        //           items: AdmissionStatus.editable
        //               .map(
        //                 (item) => DropdownMenuItem(
        //                   value: item,
        //                   child: Text(item.displayLabel),
        //                 ),
        //               )
        //               .toList(),
        //           onChanged: submitting ? null : onStatusChanged,
        //         ),
        //       _DateTile(
        //         icon: Icons.login,
        //         label: AppTexts.admitted,
        //         value: dateComes != null
        //             ? admissionDetailsSqlDateTime(dateComes!)
        //             : AppTexts.notAvailable,
        //         onTap: isEdit || submitting ? null : onPickDateComes,
        //       ),
        //       if (isEdit) ...[
        //         _DateTile(
        //           icon: Icons.logout,
        //           label: AppTexts.dischargedLabel,
        //           value: dateLeave != null
        //               ? admissionDetailsSqlDateTime(dateLeave!)
        //               : 'Not set',
        //           onTap: submitting ? null : onPickDateLeave,
        //           onClear: dateLeave != null && !submitting
        //               ? onClearDateLeave
        //               : null,
        //         ),
        //         _DateTile(
        //           icon: Icons.event_busy,
        //           label: AppTexts.dateOfDeathLabel,
        //           value: dateOfDeath != null
        //               ? admissionDetailsSqlDateTime(dateOfDeath!)
        //               : 'Not set',
        //           onTap: submitting ? null : onPickDateOfDeath,
        //           onClear: dateOfDeath != null && !submitting
        //               ? onClearDateOfDeath
        //               : null,
        //         ),
        //       ],
        //     ],
        //   ),
        // ),
      ],
    );
  }
}

class _PatientSummary extends StatelessWidget {
  const _PatientSummary({required this.patient});

  final AdmissionPatientModel? patient;

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (patient == null) {
      return const Text(
        AppTexts.notAvailable,
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    final chips = <Widget>[
      AdmissionDetailsMetaChip(
        label: AppTexts.age,
        value: '${patient!.age}',
        icon: Icons.cake_outlined,
      ),
      if (_hasText(patient!.gender))
        AdmissionDetailsMetaChip(
          label: AppTexts.gender,
          value: patient!.gender,
          icon: Icons.wc_outlined,
        ),
      if (_hasText(patient!.bloodGroup))
        AdmissionDetailsMetaChip(
          label: AppTexts.bloodGroup,
          value: patient!.bloodGroup,
          icon: Icons.bloodtype,
        ),
      if (_hasText(patient!.phone))
        AdmissionDetailsMetaChip(
          label: AppTexts.phone,
          value: patient!.phone,
          icon: Icons.phone_outlined,
        ),
      if (_hasText(patient!.nationalId))
        AdmissionDetailsMetaChip(
          label: AppTexts.nationalId,
          value: patient!.nationalId,
          icon: Icons.badge_outlined,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          patient!.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: chips,
          ),
        ],
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.onClear,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(icon, size: 20, color: AppColors.primary),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: onClear != null
          ? IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onClear,
            )
          : (onTap != null
              ? const Icon(Icons.chevron_right, color: AppColors.textSecondary)
              : null),
      onTap: onTap,
    );
  }
}
