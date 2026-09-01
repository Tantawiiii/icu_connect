import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
import '../../../../core/utils/measurement_title_form_helpers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/measurement_title_form_fields.dart';
import '../cubit/labs_titles_cubit.dart';
import '../cubit/labs_titles_state.dart';
import '../models/lab_title_model.dart';
import '../models/lab_title_request.dart';

class LabsTitleFormScreen extends StatelessWidget {
  const LabsTitleFormScreen({super.key, this.lab});

  final LabTitleModel? lab;

  @override
  Widget build(BuildContext context) {
    return _LabsTitleFormView(lab: lab);
  }
}

class _LabsTitleFormView extends StatefulWidget {
  const _LabsTitleFormView({this.lab});

  final LabTitleModel? lab;

  @override
  State<_LabsTitleFormView> createState() => _LabsTitleFormViewState();
}

class _LabsTitleFormViewState extends State<_LabsTitleFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  late String _valueType;

  bool get _isEdit => widget.lab != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.lab?.title ?? '');
    _unitCtrl = TextEditingController(text: widget.lab?.unit ?? '');
    _minCtrl = TextEditingController(text: widget.lab?.normalRangeMin ?? '');
    _maxCtrl = TextEditingController(text: widget.lab?.normalRangeMax ?? '');
    _valueType = widget.lab?.valueType ?? 'numeric';
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

    final request = LabTitleRequest(
      title: values.title,
      unit: values.unit,
      valueType: values.valueType,
      normalRangeMin: values.normalRangeMin,
      normalRangeMax: values.normalRangeMax,
    );

    final cubit = context.read<LabsTitlesCubit>();
    if (_isEdit) {
      cubit.updateLabTitle(widget.lab!.id, request);
    } else {
      cubit.createLabTitle(request);
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
          _isEdit ? AppTexts.editLabTitle : AppTexts.addLabTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<LabsTitlesCubit, LabsTitlesState>(
        builder: (context, state) {
          final isLoading = state is LabsTitlesLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Creates a global lab title available across the hospital.',
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
                        ? AppTexts.editLabTitle
                        : AppTexts.addLabTitle,
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _submit,
                    leadingIcon: Icon(
                      _isEdit ? Icons.save_outlined : Icons.add_chart_outlined,
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
