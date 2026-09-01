import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';

import '../../home/models/doctor_hospital.dart';

class HospitalSwapGroupQuickPicker extends StatelessWidget {
  const HospitalSwapGroupQuickPicker({
    super.key,
    required this.groups,
    required this.selectedGroupId,
    required this.firstGroupId,
    required this.occupiedByGroupId,
    required this.onGroupSelected,
  });

  final List<HospitalGroup> groups;
  final int? selectedGroupId;
  final int? firstGroupId;
  final Map<int, int> occupiedByGroupId;
  final ValueChanged<int> onGroupSelected;

  @override
  Widget build(BuildContext context) {
    final visibleGroups = groups
        .where((g) => (occupiedByGroupId[g.id] ?? 0) > 0)
        .toList();
    if (visibleGroups.length < 2) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibleGroups.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final group = visibleGroups[index];
          final isSelected = group.id == selectedGroupId;
          final isFirstGroup = group.id == firstGroupId;
          final occupied = occupiedByGroupId[group.id] ?? 0;

          return Material(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.14)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onGroupSelected(group.id),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : isFirstGroup
                        ? AppColors.primary.withValues(alpha: 0.45)
                        : AppColors.border,
                    width: isSelected ? 1.6 : 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isFirstGroup) ...[
                      Icon(
                        Icons.looks_one_rounded,
                        size: 16,
                        color: AppColors.primary.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      group.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$occupied',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
