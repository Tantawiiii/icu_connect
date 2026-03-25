import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';

import '../enums/admission_status.dart';

class AdmissionStatusFilterRow extends StatelessWidget {
  const AdmissionStatusFilterRow({
    super.key,
    required this.statuses,
    required this.selected,
    required this.onSelected,
  });

  final List<AdmissionStatus> statuses;
  final AdmissionStatus selected;
  final ValueChanged<AdmissionStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final s = statuses[i];
          final isSelected = s == selected;
          return ChoiceChip(
            selected: isSelected,
            label: Text(s.label),
            onSelected: (_) => onSelected(s),
            selectedColor: AppColors.primary.withValues(alpha: 0.18),
            labelStyle: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
            side: const BorderSide(color: AppColors.border),
            backgroundColor: AppColors.background,
          );
        },
      ),
    );
  }
}

