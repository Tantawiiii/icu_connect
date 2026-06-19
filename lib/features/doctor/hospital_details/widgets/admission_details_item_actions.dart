import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';

class AdmissionDetailsItemActions extends StatelessWidget {
  const AdmissionDetailsItemActions({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: AppTexts.editEntry,
          onPressed: onEdit,
          icon: const Icon(
            Icons.edit_outlined,
            size: 18,
            color: AppColors.primary,
          ),
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          tooltip: AppTexts.deleteEntry,
          onPressed: onDelete,
          icon: const Icon(
            Icons.delete_outline,
            size: 18,
            color: Colors.redAccent,
          ),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
