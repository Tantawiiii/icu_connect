import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_texts.dart';
import '../utils/measurement_title_form_helpers.dart';
import 'app_text_field.dart';

class MeasurementTitleFormFields extends StatelessWidget {
  const MeasurementTitleFormFields({
    super.key,
    required this.titleController,
    required this.unitController,
    required this.minController,
    required this.maxController,
    required this.enabled,
    this.showValueType = false,
    this.valueType = 'numeric',
    this.onValueTypeChanged,
    this.onRangeFieldChanged,
    this.onSubmit,
  });

  final TextEditingController titleController;
  final TextEditingController unitController;
  final TextEditingController minController;
  final TextEditingController maxController;
  final bool enabled;
  final bool showValueType;
  final String valueType;
  final ValueChanged<String?>? onValueTypeChanged;
  final VoidCallback? onRangeFieldChanged;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: titleController,
          labelText: AppTexts.name,
          prefixIcon: const Icon(Icons.label_outline),
          textInputAction: TextInputAction.next,
          enabled: enabled,
          validator: MeasurementTitleFormValues.validateTitle,
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: unitController,
          labelText: '${AppTexts.unit} (optional)',
        ),
        if (showValueType) ...[
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: valueType,
            decoration: const InputDecoration(
              labelText: 'Value type',
              prefixIcon: Icon(Icons.tune_outlined),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'numeric',
                child: Text('Numeric'),
              ),
              DropdownMenuItem(
                value: 'string',
                child: Text('Text (e.g. Normal / Elevated)'),
              ),
            ],
            onChanged: enabled ? onValueTypeChanged : null,
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: minController,
                labelText: '${AppTexts.normalRangeMin} (optional)',
                prefixIcon: const Icon(Icons.arrow_downward),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                enabled: enabled,
                onChanged: (_) => onRangeFieldChanged?.call(),
                validator: (v) => MeasurementTitleFormValues.validateRangeMin(
                  v,
                  maxRaw: maxController.text,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: maxController,
                labelText: '${AppTexts.normalRangeMax} (optional)',
                prefixIcon: const Icon(Icons.arrow_upward),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                enabled: enabled,
                onChanged: (_) => onRangeFieldChanged?.call(),
                onFieldSubmitted: (_) => onSubmit?.call(),
                validator: (v) => MeasurementTitleFormValues.validateRangeMax(
                  v,
                  minRaw: minController.text,
                ),
              ),
            ),
          ],
        ),
        if (showValueType && valueType == 'string') ...[
          const SizedBox(height: 10),
          Text(
            'Text vitals accept free-text readings (e.g. Normal, Elevated).',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ],
    );
  }
}
