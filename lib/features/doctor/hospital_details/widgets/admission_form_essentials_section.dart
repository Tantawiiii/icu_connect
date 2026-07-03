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
    required this.patients,
    required this.selectedPatient,
    required this.onPatientChanged,
    required this.onAddPatient,
    required this.onStatusChanged,
    required this.onPickDateComes,
    required this.onPickDateLeave,
    required this.onClearDateLeave,
    required this.onPickDateOfDeath,
    required this.onClearDateOfDeath,
    required this.bedValidator,
    required this.patientValidator,
    this.hospitalGroupId,
  });

  final bool isEdit;
  final bool submitting;
  final TextEditingController bedCtrl;
  final AdmissionStatus status;
  final DateTime? dateComes;
  final DateTime? dateLeave;
  final DateTime? dateOfDeath;
  final List<AdmissionPatientModel> patients;
  final AdmissionPatientModel? selectedPatient;
  final ValueChanged<AdmissionPatientModel?> onPatientChanged;
  final VoidCallback onAddPatient;
  final ValueChanged<AdmissionStatus?> onStatusChanged;
  final VoidCallback onPickDateComes;
  final VoidCallback onPickDateLeave;
  final VoidCallback onClearDateLeave;
  final VoidCallback onPickDateOfDeath;
  final VoidCallback onClearDateOfDeath;
  final String? Function(String?)? bedValidator;
  final String? Function(AdmissionPatientModel?)? patientValidator;
  final int? hospitalGroupId;

  AdmissionPatientModel? _dropdownValue() {
    final selected = selectedPatient;
    if (selected == null) return null;
    for (final patient in patients) {
      if (patient.id == selected.id) return patient;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdmissionDetailsSectionContainer(
          title: AppTexts.patientLabel,
          child: isEdit
              ? _PatientSummary(patient: selectedPatient)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<AdmissionPatientModel>(
                            value: _dropdownValue(),
                            decoration: const InputDecoration(
                              labelText: AppTexts.patientLabel,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                            ),
                            hint: Text(AppTexts.selectPatient),
                            isExpanded: true,
                            items: patients
                                .map(
                                  (patient) => DropdownMenuItem(
                                    value: patient,
                                    child: Text(
                                      '${patient.name} · ${patient.nationalId}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: submitting ? null : onPatientChanged,
                            validator: (_) => patientValidator?.call(
                              selectedPatient,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: IconButton(
                            tooltip: AppTexts.addPatientAdmin,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              foregroundColor: AppColors.primary,
                            ),
                            onPressed: submitting ? null : onAddPatient,
                            icon: const Icon(Icons.person_add_outlined),
                          ),
                        ),
                      ],
                    ),
                    if (selectedPatient != null) ...[
                      const SizedBox(height: 12),
                      _PatientSummary(patient: selectedPatient),
                    ] else if (patients.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'No patients found. Add a patient first.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        AdmissionDetailsSectionContainer(
          title: isEdit ? AppTexts.editAdmission : AppTexts.createAdmission,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: bedCtrl,
                hintText: AppTexts.bedNo,
                keyboardType: TextInputType.number,
                validator: bedValidator,
              ),
              if (hospitalGroupId != null) ...[
                const SizedBox(height: 10),
                AdmissionDetailsMetaChip(
                  label: AppTexts.hospitalGroupsSummary,
                  value: '#$hospitalGroupId',
                  icon: Icons.local_hospital_outlined,
                ),
              ],
              const SizedBox(height: 12),
              if (isEdit)
                DropdownButtonFormField<AdmissionStatus>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: AppTexts.status,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  items: AdmissionStatus.editable
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.displayLabel),
                        ),
                      )
                      .toList(),
                  onChanged: submitting ? null : onStatusChanged,
                ),
              _DateTile(
                icon: Icons.login,
                label: AppTexts.admitted,
                value: dateComes != null
                    ? admissionDetailsSqlDateTime(dateComes!)
                    : AppTexts.notAvailable,
                onTap: isEdit || submitting ? null : onPickDateComes,
              ),
              if (isEdit) ...[
                _DateTile(
                  icon: Icons.logout,
                  label: AppTexts.dischargedLabel,
                  value: dateLeave != null
                      ? admissionDetailsSqlDateTime(dateLeave!)
                      : 'Not set',
                  onTap: submitting ? null : onPickDateLeave,
                  onClear: dateLeave != null && !submitting
                      ? onClearDateLeave
                      : null,
                ),
                _DateTile(
                  icon: Icons.event_busy,
                  label: AppTexts.dateOfDeathLabel,
                  value: dateOfDeath != null
                      ? admissionDetailsSqlDateTime(dateOfDeath!)
                      : 'Not set',
                  onTap: submitting ? null : onPickDateOfDeath,
                  onClear: dateOfDeath != null && !submitting
                      ? onClearDateOfDeath
                      : null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PatientSummary extends StatelessWidget {
  const _PatientSummary({required this.patient});

  final AdmissionPatientModel? patient;

  @override
  Widget build(BuildContext context) {
    if (patient == null) {
      return const Text(
        AppTexts.notAvailable,
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        AdmissionDetailsMetaChip(
          label: AppTexts.name,
          value: patient!.name,
          icon: Icons.person_outline,
        ),
        AdmissionDetailsMetaChip(
          label: AppTexts.age,
          value: '${patient!.age}',
          icon: Icons.cake_outlined,
        ),
        if (patient!.gender.trim().isNotEmpty)
          AdmissionDetailsMetaChip(
            label: AppTexts.gender,
            value: patient!.gender,
            icon: Icons.wc_outlined,
          ),
        if (patient!.bloodGroup.trim().isNotEmpty)
          AdmissionDetailsMetaChip(
            label: AppTexts.bloodGroup,
            value: patient!.bloodGroup,
            icon: Icons.bloodtype,
          ),
        if (patient!.phone.trim().isNotEmpty)
          AdmissionDetailsMetaChip(
            label: AppTexts.phone,
            value: patient!.phone,
            icon: Icons.phone_outlined,
          ),
        if (patient!.nationalId.trim().isNotEmpty)
          AdmissionDetailsMetaChip(
            label: AppTexts.nationalId,
            value: patient!.nationalId,
            icon: Icons.badge_outlined,
          ),
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
