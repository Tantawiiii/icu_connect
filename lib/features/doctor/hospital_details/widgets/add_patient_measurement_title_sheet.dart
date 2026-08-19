import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/utils/measurement_title_form_helpers.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/measurement_title_form_fields.dart';

class AddPatientMeasurementTitleSheet extends StatefulWidget {
  const AddPatientMeasurementTitleSheet({super.key, required this.isLabs});

  final bool isLabs;

  static Future<MeasurementTitleFormValues?> show(
    BuildContext context, {
    required bool isLabs,
  }) {
    return showModalBottomSheet<MeasurementTitleFormValues>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddPatientMeasurementTitleSheet(isLabs: isLabs),
    );
  }

  @override
  State<AddPatientMeasurementTitleSheet> createState() =>
      _AddPatientMeasurementTitleSheetState();
}

class _AddPatientMeasurementTitleSheetState
    extends State<AddPatientMeasurementTitleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  String _valueType = 'numeric';

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
      valueType: widget.isLabs ? 'numeric' : _valueType,
    );
    if (values == null) return;

    Navigator.pop(context, values);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.isLabs ? AppTexts.addLabTitle : AppTexts.addVitalTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.isLabs
                  ? 'Add a custom lab for this patient only.'
                  : 'Add a custom vital for this patient only.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            MeasurementTitleFormFields(
              titleController: _titleCtrl,
              unitController: _unitCtrl,
              minController: _minCtrl,
              maxController: _maxCtrl,
              enabled: true,
              showValueType: !widget.isLabs,
              valueType: _valueType,
              onValueTypeChanged: (v) {
                if (v != null) setState(() => _valueType = v);
              },
              onRangeFieldChanged: _onRangeFieldChanged,
              onSubmit: _submit,
            ),
            const SizedBox(height: 20),
            AppButton(
              label: widget.isLabs ? 'Add lab' : 'Add vital',
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
