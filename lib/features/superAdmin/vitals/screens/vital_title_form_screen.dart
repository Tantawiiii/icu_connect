import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
import '../../../../core/utils/measurement_title_form_helpers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/measurement_title_form_fields.dart';
import '../cubit/vitals_titles_cubit.dart';
import '../cubit/vitals_titles_state.dart';
import '../models/vital_title_model.dart';
import '../models/vital_title_request.dart';

/// Push with [BlocProvider.value] from [VitalsTitlesListScreen] so the cubit
/// is in scope (a new route is not under the list’s [BlocProvider]).
class VitalTitleFormScreen extends StatelessWidget {
  const VitalTitleFormScreen({super.key, this.vital});

  final VitalTitleModel? vital;

  @override
  Widget build(BuildContext context) {
    return _VitalTitleFormView(vital: vital);
  }
}

class _VitalTitleFormView extends StatefulWidget {
  const _VitalTitleFormView({this.vital});

  final VitalTitleModel? vital;

  @override
  State<_VitalTitleFormView> createState() => _VitalTitleFormViewState();
}

class _VitalTitleFormViewState extends State<_VitalTitleFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  late String _valueType;

  bool get _isEdit => widget.vital != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.vital?.title ?? '');
    _unitCtrl = TextEditingController(text: widget.vital?.unit ?? '');
    _minCtrl = TextEditingController(text: widget.vital?.normalRangeMin ?? '');
    _maxCtrl = TextEditingController(text: widget.vital?.normalRangeMax ?? '');
    _valueType = widget.vital?.valueType ?? 'numeric';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _unitCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _onRangeFieldChanged() {
    _formKey.currentState?.validate();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final values = MeasurementTitleFormValues.fromFields(
      title: _titleCtrl.text,
      unit: _unitCtrl.text,
      min: _minCtrl.text,
      max: _maxCtrl.text,
      valueType: _valueType,
    );
    if (values == null) return;

    final request = VitalTitleRequest(
      title: values.title,
      unit: values.unit,
      valueType: values.valueType,
      normalRangeMin: values.normalRangeMin,
      normalRangeMax: values.normalRangeMax,
    );

    final cubit = context.read<VitalsTitlesCubit>();
    if (_isEdit) {
      cubit.updateVitalTitle(widget.vital!.id, request);
    } else {
      cubit.createVitalTitle(request);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isEdit ? AppTexts.editVitalTitle : AppTexts.addVitalTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<VitalsTitlesCubit, VitalsTitlesState>(
        builder: (context, state) {
          final isLoading = state is VitalsTitlesLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Creates a global vitals title available across the hospital.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 16),
                  MeasurementTitleFormFields(
                    titleController: _titleCtrl,
                    unitController: _unitCtrl,
                    minController: _minCtrl,
                    maxController: _maxCtrl,
                    enabled: !isLoading,
                    showValueType: true,
                    valueType: _valueType,
                    onValueTypeChanged: (v) {
                      if (v != null) setState(() => _valueType = v);
                    },
                    onRangeFieldChanged: _onRangeFieldChanged,
                    onSubmit: _submit,
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    label: _isEdit
                        ? AppTexts.editVitalTitle
                        : AppTexts.addVitalTitle,
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _submit,
                    leadingIcon: Icon(
                      _isEdit
                          ? Icons.save_outlined
                          : Icons.monitor_heart_outlined,
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
