import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../cubit/drugs_cubit.dart';
import '../cubit/drugs_state.dart';
import '../models/drug_model.dart';
import '../models/drug_request.dart';
import '../widgets/string_list_editor.dart';

class DrugFormScreen extends StatelessWidget {
  const DrugFormScreen({super.key, this.drug});

  final DrugModel? drug;

  @override
  Widget build(BuildContext context) {
    return _DrugFormView(drug: drug);
  }
}

class _DrugFormView extends StatefulWidget {
  const _DrugFormView({this.drug});

  final DrugModel? drug;

  @override
  State<_DrugFormView> createState() => _DrugFormViewState();
}

class _DrugFormViewState extends State<_DrugFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _genericNameCtrl;
  late final TextEditingController _renalCtrl;
  late final TextEditingController _hepaticCtrl;
  late final TextEditingController _notesCtrl;

  late List<String> _tradeNames;
  late List<String> _dosingGuidelines;
  late List<String> _indications;
  late List<String> _contraindications;
  late List<String> _sideEffects;
  late List<String> _pregnancy;
  late bool _isActive;

  bool get _isEdit => widget.drug != null;

  @override
  void initState() {
    super.initState();
    final d = widget.drug;
    _genericNameCtrl = TextEditingController(text: d?.genericName ?? '');
    _renalCtrl = TextEditingController(text: d?.renalDoseAdjustment ?? '');
    _hepaticCtrl = TextEditingController(text: d?.hepaticDoseAdjustment ?? '');
    _notesCtrl = TextEditingController(text: d?.notes ?? '');
    _tradeNames = List<String>.from(d?.tradeNames ?? const []);
    _dosingGuidelines = List<String>.from(d?.dosingGuidelines ?? const []);
    _indications = List<String>.from(d?.indications ?? const []);
    _contraindications = List<String>.from(d?.contraindications ?? const []);
    _sideEffects = List<String>.from(d?.sideEffects ?? const []);
    _pregnancy = List<String>.from(d?.pregnancy ?? const []);
    _isActive = d?.isActive ?? true;
  }

  @override
  void dispose() {
    _genericNameCtrl.dispose();
    _renalCtrl.dispose();
    _hepaticCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

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

    final cubit = context.read<DrugsCubit>();
    if (_isEdit) {
      cubit.updateDrug(widget.drug!.id, request);
    } else {
      cubit.createDrug(request);
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isEdit ? AppTexts.editDrug : AppTexts.addDrug,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<DrugsCubit, DrugsState>(
        builder: (context, state) {
          final isLoading =
              state is DrugsLoading || state is DrugsActionLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _genericNameCtrl,
                    labelText: '${AppTexts.genericName} *',
                    enabled: !isLoading,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(255),
                    ],
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
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(2000),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _hepaticCtrl,
                    labelText: AppTexts.hepaticDoseAdjustment,
                    enabled: !isLoading,
                    maxLines: 3,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(2000),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _notesCtrl,
                    labelText: AppTexts.notes,
                    enabled: !isLoading,
                    maxLines: 4,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(5000),
                    ],
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    label: _isEdit ? AppTexts.editDrug : AppTexts.addDrug,
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _submit,
                    leadingIcon: Icon(
                      _isEdit
                          ? Icons.save_outlined
                          : Icons.medication_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
