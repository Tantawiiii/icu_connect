import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/app_text_field.dart';
import 'package:icu_connect/features/superAdmin/drugs/models/drug_model.dart';
import 'package:icu_connect/features/superAdmin/drugs/models/drug_request.dart';
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
  late final TextEditingController _renalCtrl;
  late final TextEditingController _hepaticCtrl;
  late final TextEditingController _notesCtrl;

  List<String> _tradeNames = [];
  List<String> _dosingGuidelines = [];
  List<String> _indications = [];
  List<String> _contraindications = [];
  List<String> _sideEffects = [];
  List<String> _pregnancy = [];
  bool _isActive = true;

  bool _aiLoading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _genericNameCtrl = TextEditingController(
      text: widget.initialGenericName ?? '',
    );
    _renalCtrl = TextEditingController();
    _hepaticCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _genericNameCtrl.dispose();
    _tradeNameAiCtrl.dispose();
    _renalCtrl.dispose();
    _hepaticCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _hasAiData =>
      _tradeNames.isNotEmpty ||
      _dosingGuidelines.isNotEmpty ||
      _indications.isNotEmpty ||
      _contraindications.isNotEmpty ||
      _sideEffects.isNotEmpty ||
      _pregnancy.isNotEmpty ||
      _renalCtrl.text.trim().isNotEmpty ||
      _hepaticCtrl.text.trim().isNotEmpty;

  Future<void> _fillWithAi({bool silent = false}) async {
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

    setState(() => _aiLoading = true);
    try {
      final result = await _repo.lookupDrugWithAi(
        genericName: generic.isEmpty ? null : generic,
        tradeNames: tradeNames,
      );
      if (!mounted) return;
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
        _isActive = result.isActive;
        _aiLoading = false;
      });
      if (!mounted) return;
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppTexts.aiDrugLookupSuccess)),
        );
      }
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
    _renalCtrl.clear();
    _hepaticCtrl.clear();
    _notesCtrl.clear();
    setState(() {
      _tradeNames = [];
      _dosingGuidelines = [];
      _indications = [];
      _contraindications = [];
      _sideEffects = [];
      _pregnancy = [];
      _isActive = true;
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
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
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            AppTexts.aiDrugLookupHint,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      controller: _tradeNameAiCtrl,
                      labelText: 'Trade name (optional, for AI lookup)',
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 42,
                      child: AppButton(
                        label: _aiLoading ? 'Asking AI…' : AppTexts.fillWithAi,
                        isLoading: _aiLoading,
                        onPressed: isLoading ? null : _fillWithAi,
                        leadingIcon: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
