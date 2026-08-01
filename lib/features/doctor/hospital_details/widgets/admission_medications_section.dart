import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/app_text_field.dart';
import 'package:icu_connect/features/superAdmin/drugs/models/drug_model.dart';
import 'package:icu_connect/features/superAdmin/patients/models/patient_admission_models.dart';

import '../repository/hospital_drugs_repository.dart';
import 'admission_details_empty_hint.dart';
import 'admission_details_section_container.dart';
import 'drug_picker_field.dart';

typedef MedicationSaveCallback = void Function({
  required int drugId,
  required String title,
  required String dose,
  required String frequency,
  String type,
});

class AdmissionMedicationsSection extends StatelessWidget {
  const AdmissionMedicationsSection({
    super.key,
    required this.medications,
    required this.adding,
    required this.editingItemId,
    required this.saving,
    required this.onStartAdd,
    required this.onCancelAdd,
    required this.onSaveAdd,
    required this.onBeginEdit,
    required this.onCancelEdit,
    required this.onSaveEdit,
    required this.onDiscontinue,
    required this.onDelete,
    this.initialEdit,
  });

  final List<MedicationModel> medications;
  final bool adding;
  final int? editingItemId;
  final bool saving;
  final VoidCallback onStartAdd;
  final VoidCallback onCancelAdd;
  final MedicationSaveCallback onSaveAdd;
  final void Function(MedicationModel med) onBeginEdit;
  final VoidCallback onCancelEdit;
  final MedicationSaveCallback onSaveEdit;
  final void Function(MedicationModel med) onDiscontinue;
  final void Function(MedicationModel med) onDelete;
  final MedicationModel? initialEdit;

  static const routeTypes = <String>[
    'PO',
    'IV',
    'IM',
    'SC',
    'infusion',
    'syring_pump',
    'bolus',
    'other',
  ];

  @override
  Widget build(BuildContext context) {
    final canAdd = !adding && editingItemId == null;

    return AdmissionDetailsSectionContainer(
      title: 'Active Medications',
      headerAction: canAdd
          ? IconButton(
              tooltip: 'Add medication',
              icon: const Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
                size: 20,
              ),
              onPressed: onStartAdd,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SafetyQuickBar(medications: medications),
          const SizedBox(height: 12),
          if (adding)
            _MedicationForm(
              saving: saving,
              title: 'Add medication',
              onCancel: onCancelAdd,
              onSave: onSaveAdd,
            ),
          if (medications.isEmpty && !adding)
            const AdmissionDetailsEmptyHint('No medications recorded.')
          else
            for (final med in medications) ...[
              if (editingItemId == med.id)
                _MedicationForm(
                  saving: saving,
                  title: 'Edit medication',
                  isEditing: true,
                  initial: initialEdit ?? med,
                  onCancel: onCancelEdit,
                  onSave: onSaveEdit,
                )
              else
                _MedicationCard(
                  med: med,
                  onEdit: () => onBeginEdit(med),
                  onDiscontinue: () => onDiscontinue(med),
                  onDelete: () => onDelete(med),
                ),
            ],
        ],
      ),
    );
  }
}

class _SafetyQuickBar extends StatelessWidget {
  const _SafetyQuickBar({required this.medications});

  final List<MedicationModel> medications;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SafetyTile(
          icon: Icons.verified_user_outlined,
          label: 'Interactions',
          onTap: () => _showInfo(
            context,
            'Interactions',
            'Review drug–drug interactions for active medications with pharmacy / formulary guidance.',
          ),
        ),
        const SizedBox(width: 8),
        _SafetyTile(
          icon: Icons.bloodtype_outlined,
          label: 'Hepatic',
          onTap: () => _showInfo(
            context,
            'Hepatic',
            'Check hepatic dose adjustments for each active medication when hepatic impairment is present.',
          ),
        ),
        const SizedBox(width: 8),
        _SafetyTile(
          icon: Icons.pregnant_woman_outlined,
          label: 'Pregnancy',
          onTap: () => _showInfo(
            context,
            'Pregnancy',
            'Review pregnancy category / caution notes for active medications.',
          ),
        ),
        const SizedBox(width: 8),
        _SafetyTile(
          icon: Icons.child_care_outlined,
          label: 'Lactation',
          onTap: () => _showInfo(
            context,
            'Lactation',
            'Confirm lactation safety for active medications before continuing therapy.',
          ),
        ),
      ],
    );
  }

  void _showInfo(BuildContext context, String title, String body) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            if (medications.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Active: ${medications.map((m) => m.title).join(', ')}',
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SafetyTile extends StatelessWidget {
  const _SafetyTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: const Color(0xFFF2F3F5),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Icon(icon, size: 20, color: AppColors.textSecondary),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.med,
    required this.onEdit,
    required this.onDiscontinue,
    required this.onDelete,
  });

  final MedicationModel med;
  final VoidCallback onEdit;
  final VoidCallback onDiscontinue;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final route = med.type.trim().isEmpty
        ? ''
        : med.type.replaceAll('_', ' ').toUpperCase();
    final dose = med.value.trim();
    final freq = med.duration.trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.title.isEmpty
                      ? (med.drugId != null
                          ? 'Drug #${med.drugId}'
                          : 'Medication')
                      : med.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (dose.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF0F3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          dose,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    if (route.isNotEmpty)
                      Text(
                        route,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (freq.isNotEmpty)
                      Text(
                        '· $freq',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: AppTexts.editEntry,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: AppColors.textSecondary,
            visualDensity: VisualDensity.compact,
          ),
          TextButton(
            onPressed: onDiscontinue,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFFEBEE),
              foregroundColor: const Color(0xFFD32F2F),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'DC',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          IconButton(
            tooltip: AppTexts.deleteEntry,
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            color: AppColors.textSecondary,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _MedicationForm extends StatefulWidget {
  const _MedicationForm({
    required this.saving,
    required this.title,
    required this.onCancel,
    required this.onSave,
    this.isEditing = false,
    this.initial,
  });

  final bool saving;
  final String title;
  final bool isEditing;
  final MedicationModel? initial;
  final VoidCallback onCancel;
  final MedicationSaveCallback onSave;

  @override
  State<_MedicationForm> createState() => _MedicationFormState();
}

class _MedicationFormState extends State<_MedicationForm> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _doseCtrl;
  late final TextEditingController _freqCtrl;
  late String _route;
  DrugModel? _selectedDrug;
  int? _drugId;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleCtrl = TextEditingController(text: initial?.title ?? '');
    _doseCtrl = TextEditingController(text: initial?.value ?? '');
    _freqCtrl = TextEditingController(text: initial?.duration ?? '');
    _drugId = initial?.drugId;
    final type = (initial?.type ?? 'PO').trim();
    _route = AdmissionMedicationsSection.routeTypes.contains(type)
        ? type
        : (type.isEmpty ? 'PO' : 'other');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _doseCtrl.dispose();
    _freqCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final drugId = _selectedDrug?.id ?? _drugId;
    final dose = _doseCtrl.text.trim();
    final frequency = _freqCtrl.text.trim();
    if (drugId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a drug from the formulary'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (dose.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dose is required'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (frequency.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Frequency is required'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final title = _selectedDrug != null
        ? hospitalDrugDisplayName(_selectedDrug!)
        : _titleCtrl.text.trim();
    widget.onSave(
      drugId: drugId,
      title: title.isEmpty ? 'Drug #$drugId' : title,
      dose: dose,
      frequency: frequency,
      type: _route,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.saving ? null : widget.onCancel,
                icon: const Icon(Icons.close, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          DrugPickerField(
            enabled: !widget.saving,
            initialLabel: _titleCtrl.text,
            allowCustomName: false,
            label: 'Search formulary *',
            onSelected: (drug) {
              setState(() {
                _selectedDrug = drug;
                _drugId = drug.id;
                _titleCtrl.text = hospitalDrugDisplayName(drug);
              });
            },
          ),
          if (_selectedDrug != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (_selectedDrug!.hepaticDoseAdjustment.trim().isNotEmpty)
                  _MiniChip(
                    label: 'Hepatic',
                    onTap: () => _showDrugNote(
                      'Hepatic',
                      _selectedDrug!.hepaticDoseAdjustment,
                    ),
                  ),
                if (_selectedDrug!.pregnancy.isNotEmpty)
                  _MiniChip(
                    label: 'Pregnancy',
                    onTap: () => _showDrugNote(
                      'Pregnancy',
                      _selectedDrug!.pregnancy.join('\n'),
                    ),
                  ),
                if (_selectedDrug!.renalDoseAdjustment.trim().isNotEmpty)
                  _MiniChip(
                    label: 'Renal',
                    onTap: () => _showDrugNote(
                      'Renal',
                      _selectedDrug!.renalDoseAdjustment,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _route,
            decoration: const InputDecoration(
              labelText: 'Route (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            items: AdmissionMedicationsSection.routeTypes
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.replaceAll('_', ' ')),
                  ),
                )
                .toList(),
            onChanged: widget.saving
                ? null
                : (v) => setState(() => _route = v ?? 'PO'),
          ),
          const SizedBox(height: 10),
          AppTextField(
            controller: _doseCtrl,
            labelText: 'Dose *',
            hintText: 'e.g. 150 mg',
            enabled: !widget.saving,
          ),
          const SizedBox(height: 10),
          AppTextField(
            controller: _freqCtrl,
            labelText: 'Frequency *',
            hintText: 'e.g. q8h',
            enabled: !widget.saving,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: AppButton(
              label: widget.saving
                  ? 'Saving...'
                  : widget.isEditing
                      ? AppTexts.saveChanges
                      : 'Save Entry',
              onPressed: widget.saving ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }

  void _showDrugNote(String title, String body) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(body, style: const TextStyle(height: 1.45)),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: onTap,
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      visualDensity: VisualDensity.compact,
    );
  }
}
