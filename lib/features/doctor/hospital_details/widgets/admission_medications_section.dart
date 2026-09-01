import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/network/api_client.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/app_text_field.dart';
import 'package:icu_connect/features/superAdmin/drugs/models/drug_model.dart';
import 'package:icu_connect/features/superAdmin/drugs/widgets/dose_input_row.dart';
import 'package:icu_connect/features/superAdmin/patients/models/patient_admission_models.dart';

import '../repository/hospital_drugs_repository.dart';
import 'admission_details_empty_hint.dart';
import 'admission_details_section_container.dart';
import 'drug_picker_field.dart';

typedef MedicationSaveCallback =
    void Function({
      required int drugId,
      required String title,
      required String dose,
      required int? doseUnitId,
      required String frequency,
      String type,
    });

class _RouteMeta {
  const _RouteMeta(this.icon, this.color);
  final IconData icon;
  final Color color;
}

const Map<String, _RouteMeta> _routeMetaMap = {
  'infusion': _RouteMeta(Icons.opacity_outlined, Color(0xFF5C6BC0)),
  'IV': _RouteMeta(Icons.water_drop_outlined, Color(0xFF1E88E5)),
  'PO': _RouteMeta(Icons.medication_liquid_outlined, Color(0xFF3B5998)),
  'IM': _RouteMeta(Icons.vaccines_outlined, Color(0xFF00897B)),
  'SC': _RouteMeta(Icons.colorize_outlined, Color(0xFF8E24AA)),
  'syring_pump': _RouteMeta(Icons.speed_outlined, Color(0xFFEF6C00)),
  'bolus': _RouteMeta(Icons.bolt_outlined, Color(0xFFF9A825)),
  'other': _RouteMeta(Icons.medication_outlined, Color(0xFF6C6F80)),
};

const String _infusionRateUnitCode = 'ml/h';
const String _infusionFrequencyValue = 'Continuous';

_RouteMeta _routeMeta(String type) =>
    _routeMetaMap[type] ?? _routeMetaMap['other']!;

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
    'infusion',
    'IV',
    'PO',
    'IM',
    'SC',
    'syring_pump',
    'bolus',
    'other',
  ];

  static const frequencyPresets = <String>[
    '4h',
    '6h',
    '8h',
    '12h',
    '24h',
    '48h',
    '72h',
    'STAT',
    'PRN',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final canAdd = !adding && editingItemId == null;
    final activeCount = medications.where((m) => !m.isDiscontinued).length;

    return AdmissionDetailsSectionContainer(
      title: 'Active Medications',
      headerAction: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (medications.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$activeCount active',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (canAdd) _AddMedicationButton(onPressed: onStartAdd),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SafetyQuickBar(
            medications: medications
                .where((m) => !m.isDiscontinued)
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
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

class _AddMedicationButton extends StatelessWidget {
  const _AddMedicationButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 16, color: AppColors.primary),
              SizedBox(width: 4),
              Text(
                'Add',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
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
          icon: Icons.water_drop_outlined,
          label: 'Renal',
          color: const Color(0xFF3B5998),
          onTap: () => _showInfo(
            context,
            'Renal',
            'Check renal dose adjustments for each active medication when renal impairment is present.',
          ),
        ),
        const SizedBox(width: 8),
        _SafetyTile(
          icon: Icons.bloodtype_outlined,
          label: 'Hepatic',
          color: const Color(0xFFEF6C00),
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
          color: const Color(0xFFD81B60),
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
          color: const Color(0xFF00897B),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
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
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.18)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Icon(icon, size: 19, color: color),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
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
    final meta = _routeMeta(med.type.trim());
    final routeLabel = med.type.trim().isEmpty
        ? ''
        : med.type.replaceAll('_', ' ').toUpperCase();
    final dose = [
      med.value.trim(),
      med.doseUnitLabel.trim(),
    ].where((s) => s.isNotEmpty).join(' ');
    final freq = med.duration.trim();
    final discontinued = med.isDiscontinued;
    final name = med.title.isEmpty
        ? (med.drugId != null ? 'Drug #${med.drugId}' : 'Medication')
        : med.title;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: discontinued ? const Color(0xFFFAFAFA) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: discontinued
              ? AppColors.border
              : meta.color.withValues(alpha: 0.16),
        ),
        boxShadow: discontinued
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: discontinued
                      ? AppColors.border.withValues(alpha: 0.5)
                      : meta.color.withValues(alpha: 0.12),
                ),
                child: Icon(
                  meta.icon,
                  size: 19,
                  color: discontinued ? AppColors.textSecondary : meta.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: discontinued
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              decoration: discontinued
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              decorationColor: AppColors.textSecondary,
                              decorationThickness: 2,
                            ),
                          ),
                        ),
                        if (discontinued) ...[
                          const SizedBox(width: 6),
                          const _Pill(
                            label: 'DC',
                            bg: Color(0xFFFFEBEE),
                            fg: Color(0xFFD32F2F),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (routeLabel.isNotEmpty)
                          _Pill(
                            label: routeLabel,
                            bg: meta.color.withValues(alpha: 0.1),
                            fg: meta.color,
                          ),
                        if (dose.isNotEmpty)
                          _InfoChip(
                            icon: Icons.medication,
                            text: dose,
                            muted: discontinued,
                          ),
                        if (freq.isNotEmpty)
                          _InfoChip(
                            icon: Icons.schedule,
                            text: freq,
                            muted: discontinued,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: AppColors.border.withValues(alpha: 0.6)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _CardAction(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: onEdit,
                ),
              ),
              Expanded(
                child: _CardAction(
                  icon: discontinued
                      ? Icons.play_circle_outline
                      : Icons.pause_circle_outline,
                  label: discontinued ? 'Resume' : 'Stop',
                  color: discontinued
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFD32F2F),
                  onTap: onDiscontinue,
                ),
              ),
              Expanded(
                child: _CardAction(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  onTap: onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.text,
    required this.muted,
  });

  final IconData icon;
  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = muted ? AppColors.textSecondary : AppColors.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF0F3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
              decoration: muted
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textSecondary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
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
  String? _frequencyPreset;
  DrugModel? _selectedDrug;
  int? _drugId;
  int? _doseUnitId;

  bool get _isInfusion => _route == 'infusion';

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleCtrl = TextEditingController(text: initial?.title ?? '');
    _doseCtrl = TextEditingController(text: initial?.value ?? '');
    _freqCtrl = TextEditingController(text: initial?.duration ?? '');
    _drugId = initial?.drugId;
    _doseUnitId = initial?.doseUnitId;
    final type = (initial?.type ?? 'other').trim();
    _route = AdmissionMedicationsSection.routeTypes.contains(type)
        ? type
        : 'other';

    final initialFreq = initial?.duration.trim() ?? '';
    if (initialFreq.isEmpty) {
      _frequencyPreset = null;
    } else if (AdmissionMedicationsSection.frequencyPresets.contains(
          initialFreq,
        ) &&
        initialFreq != 'Other') {
      _frequencyPreset = initialFreq;
    } else {
      _frequencyPreset = 'Other';
    }
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
    final frequency = _isInfusion
        ? _infusionFrequencyValue
        : _freqCtrl.text.trim();
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
    if (_doseUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dose unit is required'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (!_isInfusion && (_frequencyPreset == null || frequency.isEmpty)) {
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
      doseUnitId: _doseUnitId,
      frequency: frequency,
      type: _route,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
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
          const SizedBox(height: 10),
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
          const SizedBox(height: 14),
          const Text(
            'Route',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final t in AdmissionMedicationsSection.routeTypes) ...[
                  Builder(
                    builder: (context) {
                      final meta = _routeMeta(t);
                      final selected = _route == t;
                      return ChoiceChip(
                        label: Text(
                          t.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        avatar: Icon(
                          meta.icon,
                          size: 14,
                          color: selected ? Colors.white : meta.color,
                        ),
                        selected: selected,
                        showCheckmark: false,
                        selectedColor: meta.color,
                        backgroundColor: meta.color.withValues(alpha: 0.08),
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: meta.color.withValues(alpha: 0.3),
                          ),
                        ),
                        onSelected: widget.saving
                            ? null
                            : (_) => setState(() {
                                final wasInfusion = _isInfusion;
                                _route = t;
                                if (wasInfusion != _isInfusion) {
                                  _doseUnitId = null;
                                }
                              }),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          DoseInputRow(
            role: UserRole.hospital,
            amountController: _doseCtrl,
            unitId: _doseUnitId,
            enabled: !widget.saving,
            amountLabel: _isInfusion ? 'Rate *' : 'Dose *',
            unitCodeFilter: _isInfusion ? const [_infusionRateUnitCode] : null,
            lockedDisplayLabel: _isInfusion ? _infusionRateUnitCode : null,
            onUnitChanged: (v) => setState(() => _doseUnitId = v),
          ),
          if (!_isInfusion) ...[
            const SizedBox(height: 14),
            const Text(
              'Frequency',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f
                      in AdmissionMedicationsSection.frequencyPresets) ...[
                    ChoiceChip(
                      label: Text(
                        f,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _frequencyPreset == f
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                      selected: _frequencyPreset == f,
                      showCheckmark: false,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.08,
                      ),
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      onSelected: widget.saving
                          ? null
                          : (_) => setState(() {
                              _frequencyPreset = f;
                              if (f == 'Other') {
                                _freqCtrl.clear();
                              } else {
                                _freqCtrl.text = f;
                              }
                            }),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            if (_frequencyPreset == 'Other') ...[
              const SizedBox(height: 10),
              AppTextField(
                controller: _freqCtrl,
                labelText: 'Custom frequency *',
                hintText: 'e.g. BID, continuous',
                enabled: !widget.saving,
              ),
            ],
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: widget.saving ? null : widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 46,
                  child: AppButton(
                    label: widget.saving
                        ? 'Saving...'
                        : widget.isEditing
                        ? AppTexts.saveChanges
                        : 'Save Entry',
                    isLoading: widget.saving,
                    onPressed: widget.saving ? null : _submit,
                  ),
                ),
              ),
            ],
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
