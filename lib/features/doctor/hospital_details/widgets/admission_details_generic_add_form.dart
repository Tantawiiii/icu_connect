import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/app_text_field.dart';

class AdmissionDetailsFormFieldSpec {
  AdmissionDetailsFormFieldSpec({
    required this.hint,
    required this.controller,
    this.maxLines = 1,
    this.isRequired = false,
  });

  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final bool isRequired;
}

class AdmissionDetailsGenericAddForm extends StatelessWidget {
  const AdmissionDetailsGenericAddForm({
    super.key,
    required this.title,
    required this.fields,
    required this.saving,
    required this.onCancel,
    required this.onSave,
    this.typeLabel,
    this.typeValue,
    this.types,
    this.onTypeChanged,
    this.childrenAfterFields = const [],
  });

  final String title;
  final List<AdmissionDetailsFormFieldSpec> fields;
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final String? typeLabel;
  final String? typeValue;
  final List<String>? types;
  final ValueChanged<String?>? onTypeChanged;
  /// Inserted after text fields (e.g. radiology image/video pickers).
  final List<Widget> childrenAfterFields;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: saving ? null : onCancel,
                icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const Divider(height: 24),
          if (types != null && onTypeChanged != null) ...[
            Text(
              typeLabel ?? 'Type',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: typeValue,
              items: types!
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: saving ? null : onTypeChanged,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
          ],
          ...fields.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppTextField(
                controller: f.controller,
                hintText: f.hint + (f.isRequired ? ' *' : ''),
                maxLines: f.maxLines,
                enabled: !saving,
              ),
            ),
          ),
          ...childrenAfterFields,
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: AppButton(
              label: saving ? 'Saving...' : 'Save Entry',
              onPressed: saving ? null : onSave,
            ),
          ),
        ],
      ),
    );
  }
}
