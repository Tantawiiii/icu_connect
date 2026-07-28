import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/app_text_field.dart';
import 'package:icu_connect/features/superAdmin/patients/models/patient_admission_models.dart';

import '../repository/hospital_drugs_repository.dart';
import 'admission_details_empty_hint.dart';
import 'admission_details_item_actions.dart';
import 'admission_details_section_container.dart';
import 'drug_picker_field.dart';

class CultureAntibioticDraftEntry {
  CultureAntibioticDraftEntry({
    this.id,
    this.drugId,
    this.drugName = '',
    this.sensitivity = 'S',
  });

  int? id;
  int? drugId;
  String drugName;
  String sensitivity;

  CultureAntibioticModel toModel(int fallbackId) => CultureAntibioticModel(
        id: id ?? fallbackId,
        drugId: drugId,
        drugName: drugName,
        sensitivity: sensitivity,
      );

  Map<String, dynamic> toApiJson({bool includeId = true}) {
    final m = <String, dynamic>{
      'sensitivity': sensitivity.toUpperCase(),
    };
    if (includeId && id != null) m['id'] = id;
    if (drugId != null) {
      m['drug_id'] = drugId;
    } else {
      final name = drugName.trim();
      if (name.isNotEmpty) m['drug_name'] = name;
    }
    return m;
  }
}

typedef CultureSaveCallback = void Function({
  required String title,
  required String note,
  required List<CultureAntibioticDraftEntry> antibiotics,
  required List<int> deletedAntibioticIds,
});

class AdmissionCulturesSection extends StatelessWidget {
  const AdmissionCulturesSection({
    super.key,
    required this.cultures,
    required this.adding,
    required this.editingItemId,
    required this.saving,
    required this.onStartAdd,
    required this.onCancelAdd,
    required this.onSaveAdd,
    required this.onBeginEdit,
    required this.onCancelEdit,
    required this.onSaveEdit,
    required this.onDelete,
  });

  final List<CultureModel> cultures;
  final bool adding;
  final int? editingItemId;
  final bool saving;
  final VoidCallback onStartAdd;
  final VoidCallback onCancelAdd;
  final CultureSaveCallback onSaveAdd;
  final void Function(CultureModel culture) onBeginEdit;
  final VoidCallback onCancelEdit;
  final CultureSaveCallback onSaveEdit;
  final void Function(int id) onDelete;

  static const sensitivities = ['S', 'I', 'R'];

  @override
  Widget build(BuildContext context) {
    final canAdd = !adding && editingItemId == null;

    return AdmissionDetailsSectionContainer(
      title: 'Cultures',
      headerAction: canAdd
          ? IconButton(
              tooltip: 'Add culture',
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
          if (adding)
            _CultureForm(
              saving: saving,
              title: 'Add culture',
              onCancel: onCancelAdd,
              onSave: onSaveAdd,
            ),
          if (cultures.isEmpty && !adding)
            const AdmissionDetailsEmptyHint('No cultures recorded.')
          else
            for (final culture in cultures) ...[
              if (editingItemId == culture.id)
                _CultureForm(
                  saving: saving,
                  title: 'Edit culture',
                  isEditing: true,
                  initial: culture,
                  onCancel: onCancelEdit,
                  onSave: onSaveEdit,
                )
              else
                _CultureCard(
                  culture: culture,
                  onEdit: () => onBeginEdit(culture),
                  onDelete: () => onDelete(culture.id),
                ),
            ],
        ],
      ),
    );
  }
}

class _CultureCard extends StatelessWidget {
  const _CultureCard({
    required this.culture,
    required this.onEdit,
    required this.onDelete,
  });

  final CultureModel culture;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color _sensitivityColor(String s) {
    switch (s.toUpperCase()) {
      case 'S':
        return AppColors.success;
      case 'R':
        return AppColors.error;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
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
                  culture.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              AdmissionDetailsItemActions(onEdit: onEdit, onDelete: onDelete),
            ],
          ),
          if (culture.note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              culture.note,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (culture.antibiotics.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Antibiotics',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: culture.antibiotics.map((a) {
                final color = _sensitivityColor(a.sensitivity);
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${a.displayName} · ${a.sensitivity.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _CultureForm extends StatefulWidget {
  const _CultureForm({
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
  final CultureModel? initial;
  final VoidCallback onCancel;
  final CultureSaveCallback onSave;

  @override
  State<_CultureForm> createState() => _CultureFormState();
}

class _CultureFormState extends State<_CultureForm> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _noteCtrl;
  late List<CultureAntibioticDraftEntry> _antibiotics;
  final List<int> _deletedAntibioticIds = [];
  String _pendingSensitivity = 'S';

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleCtrl = TextEditingController(text: initial?.title ?? '');
    _noteCtrl = TextEditingController(text: initial?.note ?? '');
    _antibiotics = (initial?.antibiotics ?? const [])
        .map(
          (a) => CultureAntibioticDraftEntry(
            id: a.id > 0 ? a.id : null,
            drugId: a.drugId,
            drugName: a.drugName,
            sensitivity: a.sensitivity,
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _removeAntibiotic(int index) {
    final entry = _antibiotics[index];
    setState(() {
      if (entry.id != null) _deletedAntibioticIds.add(entry.id!);
      _antibiotics.removeAt(index);
    });
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Culture title is required'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    widget.onSave(
      title: title,
      note: _noteCtrl.text.trim(),
      antibiotics: List<CultureAntibioticDraftEntry>.from(_antibiotics),
      deletedAntibioticIds: List<int>.from(_deletedAntibioticIds),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
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
          AppTextField(
            controller: _titleCtrl,
            labelText: 'Organism / title *',
            enabled: !widget.saving,
          ),
          const SizedBox(height: 10),
          AppTextField(
            controller: _noteCtrl,
            labelText: 'Site / note (e.g. Urine, Blood)',
            enabled: !widget.saving,
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          const Text(
            'Antibiotics sensitivity',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Sensitivity', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _pendingSensitivity,
                items: AdmissionCulturesSection.sensitivities
                    .map(
                      (s) => DropdownMenuItem(value: s, child: Text(s)),
                    )
                    .toList(),
                onChanged: widget.saving
                    ? null
                    : (v) => setState(() => _pendingSensitivity = v ?? 'S'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DrugPickerField(
            enabled: !widget.saving,
            label: 'Add antibiotic from formulary',
            onSelected: (drug) {
              setState(() {
                _antibiotics.add(
                  CultureAntibioticDraftEntry(
                    drugId: drug.id,
                    drugName: hospitalDrugDisplayName(drug),
                    sensitivity: _pendingSensitivity,
                  ),
                );
              });
            },
            onCustomName: (name) {
              setState(() {
                _antibiotics.add(
                  CultureAntibioticDraftEntry(
                    drugName: name,
                    sensitivity: _pendingSensitivity,
                  ),
                );
              });
            },
          ),
          if (_antibiotics.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...List.generate(_antibiotics.length, (index) {
              final a = _antibiotics[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        a.drugName.isEmpty
                            ? (a.drugId != null
                                ? 'Drug #${a.drugId}'
                                : 'Antibiotic')
                            : a.drugName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DropdownButton<String>(
                      value: a.sensitivity.toUpperCase(),
                      underline: const SizedBox.shrink(),
                      items: AdmissionCulturesSection.sensitivities
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: widget.saving
                          ? null
                          : (v) => setState(
                                () => a.sensitivity = v ?? 'S',
                              ),
                    ),
                    IconButton(
                      onPressed:
                          widget.saving ? null : () => _removeAntibiotic(index),
                      icon: const Icon(Icons.close, size: 16),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              );
            }),
          ],
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
}
