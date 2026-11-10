import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_spacing.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/network/api_client.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/app_text_field.dart';
import 'package:icu_connect/core/widgets/status_badge.dart';
import 'package:icu_connect/features/superAdmin/drugs/models/drug_model.dart';
import 'package:icu_connect/features/superAdmin/drugs/models/drug_request.dart';
import 'package:icu_connect/features/superAdmin/drugs/widgets/dose_input_row.dart';
import 'package:icu_connect/features/superAdmin/drugs/widgets/string_list_editor.dart';

import '../repository/hospital_drugs_repository.dart';

class AddDrugScreen extends StatefulWidget {
  const AddDrugScreen({super.key, this.initialGenericName});

  final String? initialGenericName;

  @override
  State<AddDrugScreen> createState() => _AddDrugScreenState();
}

class _AddDrugScreenState extends State<AddDrugScreen> {
  final _repo = const HospitalDrugsRepository();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _genericNameCtrl;
  final _tradeNameAiCtrl = TextEditingController();
  late final TextEditingController _doseAmountCtrl;
  late final TextEditingController _renalCtrl;
  late final TextEditingController _hepaticCtrl;
  late final TextEditingController _notesCtrl;

  List<String> _tradeNames = [];
  int? _doseUnitId;
  List<String> _dosingGuidelines = [];
  List<String> _indications = [];
  List<String> _contraindications = [];
  List<String> _sideEffects = [];
  List<String> _pregnancy = [];
  bool _isActive = true;

  bool _aiLoading = false;
  bool _saving = false;
  AiDrugLookupResult? _aiResult;
  bool _genericNameEditedManually = false;

  @override
  void initState() {
    super.initState();
    _genericNameCtrl = TextEditingController(
      text: widget.initialGenericName ?? '',
    );
    _genericNameEditedManually = _genericNameCtrl.text.trim().isNotEmpty;
    _genericNameCtrl.addListener(_onGenericNameChanged);
    _doseAmountCtrl = TextEditingController();
    _renalCtrl = TextEditingController();
    _hepaticCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    _tradeNameAiCtrl.addListener(_mirrorTradeNameIntoGeneric);
  }

  @override
  void dispose() {
    _genericNameCtrl.removeListener(_onGenericNameChanged);
    _tradeNameAiCtrl.removeListener(_mirrorTradeNameIntoGeneric);
    _genericNameCtrl.dispose();
    _tradeNameAiCtrl.dispose();
    _doseAmountCtrl.dispose();
    _renalCtrl.dispose();
    _hepaticCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onGenericNameChanged() {
    if (_genericNameCtrl.text != _tradeNameAiCtrl.text) {
      _genericNameEditedManually = _genericNameCtrl.text.trim().isNotEmpty;
    }
  }

  // Mirrors the trade-name lookup field into the generic-name field as the
  // user types, so they don't have to enter the same drug name twice before
  // tapping "Fill with AI" — stops once the user edits generic name directly.
  void _mirrorTradeNameIntoGeneric() {
    if (_genericNameEditedManually) return;
    _genericNameCtrl.value = TextEditingValue(
      text: _tradeNameAiCtrl.text,
      selection: TextSelection.collapsed(offset: _tradeNameAiCtrl.text.length),
    );
  }

  bool get _hasAiData =>
      _tradeNames.isNotEmpty ||
      _dosingGuidelines.isNotEmpty ||
      _indications.isNotEmpty ||
      _contraindications.isNotEmpty ||
      _sideEffects.isNotEmpty ||
      _pregnancy.isNotEmpty ||
      _renalCtrl.text.trim().isNotEmpty ||
      _hepaticCtrl.text.trim().isNotEmpty ||
      _doseAmountCtrl.text.trim().isNotEmpty ||
      _doseUnitId != null;

  Future<void> _fillWithAi({bool silent = false, bool refresh = false}) async {
    final generic = _genericNameCtrl.text.trim();
    final tradeNames = [
      ..._tradeNames,
      if (_tradeNameAiCtrl.text.trim().isNotEmpty) _tradeNameAiCtrl.text.trim(),
    ];
    if (generic.isEmpty && tradeNames.isEmpty) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppTexts.aiDrugLookupNameRequired)),
        );
      }
      return;
    }

    setState(() {
      _aiLoading = true;
      _aiResult = null;
    });
    try {
      final lookup = await _repo.lookupDrugWithAi(
        genericName: generic.isEmpty ? null : generic,
        tradeNames: tradeNames,
        refresh: refresh,
      );
      if (!mounted) return;

      if (!lookup.found) {
        setState(() {
          _aiLoading = false;
          _aiResult = lookup;
        });
        return;
      }

      final result = lookup.drug;
      setState(() {
        if (_genericNameCtrl.text.trim().isEmpty &&
            result.genericName.trim().isNotEmpty) {
          _genericNameCtrl.text = result.genericName;
        }
        _tradeNames = result.tradeNames.isNotEmpty
            ? result.tradeNames
            : _tradeNames;
        _tradeNameAiCtrl.clear();
        _dosingGuidelines = result.dosingGuidelines;
        _indications = result.indications;
        _contraindications = result.contraindications;
        _sideEffects = result.sideEffects;
        _pregnancy = result.pregnancy;
        _renalCtrl.text = result.renalDoseAdjustment ?? _renalCtrl.text;
        _hepaticCtrl.text = result.hepaticDoseAdjustment ?? _hepaticCtrl.text;
        _notesCtrl.text = result.notes ?? _notesCtrl.text;
        _doseAmountCtrl.text = result.doseAmount ?? _doseAmountCtrl.text;
        _doseUnitId = result.doseUnitId ?? _doseUnitId;
        _isActive = result.isActive;
        _aiLoading = false;
        _aiResult = lookup;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _aiLoading = false);
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _aiLoading = false);
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppTexts.aiDrugLookupError),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _resetFormForAnother() {
    _formKey.currentState?.reset();
    _genericNameCtrl.clear();
    _tradeNameAiCtrl.clear();
    _doseAmountCtrl.clear();
    _renalCtrl.clear();
    _hepaticCtrl.clear();
    _notesCtrl.clear();
    setState(() {
      _tradeNames = [];
      _doseUnitId = null;
      _dosingGuidelines = [];
      _indications = [];
      _contraindications = [];
      _sideEffects = [];
      _pregnancy = [];
      _isActive = true;
      _aiResult = null;
    });
  }

  Future<void> _save({bool addAnother = false}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    // Let the user just type a name and press one button — auto-fill from AI
    // first if they haven't already pressed "Fill with AI" themselves.
    if (!_hasAiData) {
      await _fillWithAi(silent: true);
      if (!mounted) return;
    }

    final request = DrugRequest(
      genericName: _genericNameCtrl.text.trim(),
      tradeNames: _tradeNames,
      dosingGuidelines: _dosingGuidelines,
      indications: _indications,
      contraindications: _contraindications,
      sideEffects: _sideEffects,
      pregnancy: _pregnancy,
      renalDoseAdjustment: _renalCtrl.text.trim(),
      hepaticDoseAdjustment: _hepaticCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      isActive: _isActive,
      doseAmount: _doseAmountCtrl.text.trim(),
      doseUnitId: _doseUnitId,
    );

    try {
      final drug = await _repo.createDrug(request);
      if (!mounted) return;
      if (addAnother) {
        _resetFormForAnother();
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppTexts.drugCreatedSuccess)),
        );
      } else {
        Navigator.of(context).pop<DrugModel>(drug);
      }
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not add drug.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _saving || _aiLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          AppTexts.addNewDrug,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            AppTexts.aiDrugLookupHint,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm + 2),
                    AppTextField(
                      controller: _tradeNameAiCtrl,
                      labelText: 'Trade name (optional, for AI lookup)',
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: AppSpacing.sm + 2),
                    SizedBox(
                      height: 42,
                      child: AppButton(
                        label: _aiLoading
                            ? 'Asking AI…'
                            : _aiResult == null
                            ? AppTexts.fillWithAi
                            : AppTexts.aiDrugLookupRegenerate,
                        isLoading: _aiLoading,
                        onPressed: isLoading
                            ? null
                            : () => _fillWithAi(refresh: _aiResult != null),
                        leadingIcon: Icon(
                          _aiResult == null
                              ? Icons.auto_awesome
                              : Icons.refresh_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: _aiResult == null
                          ? const SizedBox(width: double.infinity)
                          : Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.sm + 2,
                              ),
                              child: _AiLookupResultBanner(result: _aiResult!),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg - 4),
              AppTextField(
                controller: _genericNameCtrl,
                labelText: '${AppTexts.genericName} *',
                enabled: !isLoading,
                inputFormatters: [LengthLimitingTextInputFormatter(255)],
                validator: (v) {
                  if ((v?.trim() ?? '').isEmpty) {
                    return AppTexts.genericNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md - 4),
              DoseInputRow(
                role: UserRole.hospital,
                amountController: _doseAmountCtrl,
                unitId: _doseUnitId,
                enabled: !isLoading,
                onUnitChanged: (v) => setState(() => _doseUnitId = v),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(AppTexts.drugActive),
                value: _isActive,
                activeColor: AppColors.primary,
                onChanged: isLoading
                    ? null
                    : (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 8),
              StringListEditor(
                label: AppTexts.tradeNames,
                items: _tradeNames,
                maxLength: 255,
                enabled: !isLoading,
                onChanged: (v) => setState(() => _tradeNames = v),
              ),
              const SizedBox(height: 16),
              StringListEditor(
                label: AppTexts.dosingGuidelines,
                items: _dosingGuidelines,
                enabled: !isLoading,
                onChanged: (v) => setState(() => _dosingGuidelines = v),
              ),
              const SizedBox(height: 16),
              StringListEditor(
                label: AppTexts.indications,
                items: _indications,
                enabled: !isLoading,
                onChanged: (v) => setState(() => _indications = v),
              ),
              const SizedBox(height: 16),
              StringListEditor(
                label: AppTexts.contraindications,
                items: _contraindications,
                enabled: !isLoading,
                onChanged: (v) => setState(() => _contraindications = v),
              ),
              const SizedBox(height: 16),
              StringListEditor(
                label: AppTexts.sideEffects,
                items: _sideEffects,
                enabled: !isLoading,
                onChanged: (v) => setState(() => _sideEffects = v),
              ),
              const SizedBox(height: 16),
              StringListEditor(
                label: AppTexts.pregnancy,
                items: _pregnancy,
                enabled: !isLoading,
                onChanged: (v) => setState(() => _pregnancy = v),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _renalCtrl,
                labelText: AppTexts.renalDoseAdjustment,
                enabled: !isLoading,
                maxLines: 3,
                inputFormatters: [LengthLimitingTextInputFormatter(2000)],
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _hepaticCtrl,
                labelText: AppTexts.hepaticDoseAdjustment,
                enabled: !isLoading,
                maxLines: 3,
                inputFormatters: [LengthLimitingTextInputFormatter(2000)],
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _notesCtrl,
                labelText: AppTexts.notes,
                enabled: !isLoading,
                maxLines: 4,
                inputFormatters: [LengthLimitingTextInputFormatter(5000)],
              ),
              const SizedBox(height: 28),
              AppButton(
                label: _saving ? 'Saving…' : AppTexts.addDrug,
                isLoading: _saving,
                onPressed: isLoading ? null : () => _save(),
                leadingIcon: const Icon(
                  Icons.medication_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : () => _save(addAnother: true),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(Icons.playlist_add, size: 18),
                  label: const Text(
                    AppTexts.saveAndAddAnother,
                    style: TextStyle(fontWeight: FontWeight.w700),
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

/// Inline summary of an AI drug lookup result: confidence, gaps the model
/// flagged itself, and the sources it drew from — so the user knows exactly
/// how much to double-check before saving, without needing a transient
/// snackbar they might miss.
class _AiLookupResultBanner extends StatelessWidget {
  const _AiLookupResultBanner({required this.result});

  final AiDrugLookupResult result;

  static String _prettyFieldName(String field) {
    final words = field.split('_').where((w) => w.isNotEmpty);
    return words
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  Color _confidenceColor(String? confidence) {
    switch (confidence?.toLowerCase()) {
      case 'high':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.error;
      default:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!result.found) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 18,
              color: AppColors.error,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                AppTexts.aiDrugLookupNotFound,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    }

    final color = _confidenceColor(result.confidence);
    final confidenceLabel = (result.confidence ?? '').trim();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'AI confidence',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const Spacer(),
              if (confidenceLabel.isNotEmpty)
                StatusBadge(label: confidenceLabel.toUpperCase(), color: color),
            ],
          ),
          if (result.missingFields.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppTexts.aiDrugLookupMissingFieldsLabel,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: result.missingFields
                  .map(
                    (f) => StatusBadge(
                      label: _prettyFieldName(f),
                      color: AppColors.warning,
                    ),
                  )
                  .toList(),
            ),
          ],
          if (result.sources.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${AppTexts.aiDrugLookupSourcesLabel}: ${result.sources.join('; ')}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
