import 'package:bounce/bounce.dart';
import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';

String bedOccupancyLookupKey(int? groupId, String bedVariant) {
  final g = groupId?.toString() ?? 'null';
  return '$g::${normalizeBedNumber(bedVariant)}';
}

/// Canonical bed label for matching API values like `3`, `"03"`, or `3`.
String normalizeBedNumber(dynamic raw) {
  if (raw == null) return '';
  final text = raw is String ? raw.trim() : raw.toString().trim();
  if (text.isEmpty) return '';
  final parsed = int.tryParse(text);
  return parsed != null ? '$parsed' : text;
}

bool isBedLabelOccupied(Set<String> occupied, String bedLabel) {
  final normalized = normalizeBedNumber(bedLabel);
  if (normalized.isEmpty) return false;
  return occupied.contains(normalized);
}

int? lookupAdmissionId(Map<String, int> map, int? groupId, String bedLabel) {
  return map[bedOccupancyLookupKey(groupId, bedLabel)];
}

String? lookupPatientName(
  Map<String, String> map,
  int? groupId,
  String bedLabel,
) {
  final name = map[bedOccupancyLookupKey(groupId, bedLabel)];
  if (name != null && name.isNotEmpty) return name;
  return null;
}

class BedOccupancyData {
  const BedOccupancyData({
    required this.occupiedBedLabels,
    required this.admissionIdByBedKey,
    required this.patientNameByBedKey,
  });

  final Set<String> occupiedBedLabels;
  final Map<String, int> admissionIdByBedKey;
  final Map<String, String> patientNameByBedKey;
}

class HospitalGroupBedCard extends StatelessWidget {
  const HospitalGroupBedCard({
    super.key,
    required this.totalBeds,
    required this.groupId,
    required this.occupiedBedLabels,
    required this.admissionIdByBedKey,
    required this.patientNameByBedKey,
    required this.onBedTap,
    this.searchQuery = '',
    this.swapMode = false,
    this.firstSwapBedKey,
    this.secondSwapBedKey,
    this.onOccupiedBedLongPress,
  });

  final int totalBeds;
  final int? groupId;
  final String searchQuery;
  final Set<String> occupiedBedLabels;
  final Map<String, int> admissionIdByBedKey;
  final Map<String, String> patientNameByBedKey;
  final void Function(
    String bedNumber,
    int? hospitalGroupId,
    int? admissionIdIfOccupied,
  )
  onBedTap;
  final bool swapMode;
  final String? firstSwapBedKey;
  final String? secondSwapBedKey;
  final void Function(
    String bedNumber,
    int? hospitalGroupId,
    int admissionId,
    String patientName,
  )?
  onOccupiedBedLongPress;

  static const Color _bedRowBackground = Color(0xFFDFF5E3);
  static const Color _bedIconColor = Color(0xFF4CAF50);

  List<String> _visibleBedLabels() {
    final labels = List<String>.generate(totalBeds, (index) => '${index + 1}');
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return labels;

    return labels.where((bedLabel) {
      if (bedLabel.contains(query)) return true;
      final patientName = lookupPatientName(
        patientNameByBedKey,
        groupId,
        bedLabel,
      );
      return patientName != null && patientName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (totalBeds <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          AppTexts.noBedsInGroup,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final visibleBeds = _visibleBedLabels();
    if (visibleBeds.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          AppTexts.bedsSearchEmpty,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var index = 0; index < visibleBeds.length; index++) ...[
            if (index > 0) const SizedBox(height: 10),
            _BedRow(
              bedLabel: visibleBeds[index],
              groupId: groupId,
              occupiedBedLabels: occupiedBedLabels,
              admissionIdByBedKey: admissionIdByBedKey,
              patientNameByBedKey: patientNameByBedKey,
              onBedTap: onBedTap,
              swapMode: swapMode,
              firstSwapBedKey: firstSwapBedKey,
              secondSwapBedKey: secondSwapBedKey,
              onOccupiedBedLongPress: onOccupiedBedLongPress,
              backgroundColor: _bedRowBackground,
              iconColor: _bedIconColor,
            ),
          ],
        ],
      ),
    );
  }
}

class _BedRow extends StatelessWidget {
  const _BedRow({
    required this.bedLabel,
    required this.groupId,
    required this.occupiedBedLabels,
    required this.admissionIdByBedKey,
    required this.patientNameByBedKey,
    required this.onBedTap,
    required this.backgroundColor,
    required this.iconColor,
    this.swapMode = false,
    this.firstSwapBedKey,
    this.secondSwapBedKey,
    this.onOccupiedBedLongPress,
  });

  final String bedLabel;
  final int? groupId;
  final Set<String> occupiedBedLabels;
  final Map<String, int> admissionIdByBedKey;
  final Map<String, String> patientNameByBedKey;
  final void Function(
    String bedNumber,
    int? hospitalGroupId,
    int? admissionIdIfOccupied,
  )
  onBedTap;
  final Color backgroundColor;
  final Color iconColor;
  final bool swapMode;
  final String? firstSwapBedKey;
  final String? secondSwapBedKey;
  final void Function(
    String bedNumber,
    int? hospitalGroupId,
    int admissionId,
    String patientName,
  )?
  onOccupiedBedLongPress;

  @override
  Widget build(BuildContext context) {
    final isOccupied = isBedLabelOccupied(occupiedBedLabels, bedLabel);
    final admissionIdIfOccupied = isOccupied
        ? lookupAdmissionId(admissionIdByBedKey, groupId, bedLabel)
        : null;
    final patientName =
        lookupPatientName(patientNameByBedKey, groupId, bedLabel) ?? '';
    final bedKey = bedOccupancyLookupKey(groupId, bedLabel);
    final isFirstSelected = firstSwapBedKey == bedKey;
    final isSecondSelected = secondSwapBedKey == bedKey;
    final isSelected = isFirstSelected || isSecondSelected;

    Color rowBackground = backgroundColor;
    Color borderColor = Colors.transparent;
    double borderWidth = 0;

    if (swapMode) {
      if (!isOccupied) {
        rowBackground = backgroundColor.withValues(alpha: 0.35);
      } else if (isFirstSelected) {
        rowBackground = AppColors.primary.withValues(alpha: 0.14);
        borderColor = AppColors.primary;
        borderWidth = 2.2;
      } else if (isSecondSelected) {
        rowBackground = const Color(0xFFFFF3E0);
        borderColor = const Color(0xFFFF9800);
        borderWidth = 2.2;
      } else {
        borderColor = AppColors.primary.withValues(alpha: 0.35);
        borderWidth = 1.4;
      }
    }

    Widget row = Material(
      color: rowBackground,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onLongPress: swapMode || !isOccupied || onOccupiedBedLongPress == null
            ? null
            : () {
                if (admissionIdIfOccupied == null) return;
                onOccupiedBedLongPress!(
                  bedLabel,
                  groupId,
                  admissionIdIfOccupied,
                  patientName,
                );
              },
        child: Bounce(
          onTap: () {
            if (swapMode) {
              if (!isOccupied) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppTexts.swapBedsEmptyBedHint),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              if (admissionIdIfOccupied == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not select admission for this bed.'),
                  ),
                );
                return;
              }
            } else if (isOccupied && admissionIdIfOccupied == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not open admission for this bed.'),
                ),
              );
              return;
            }
            onBedTap(bedLabel, groupId, admissionIdIfOccupied);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                if (swapMode && isSelected) ...[
                  _SelectionBadge(
                    label: isFirstSelected ? '1' : '2',
                    color: isFirstSelected
                        ? AppColors.primary
                        : const Color(0xFFFF9800),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  bedLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: swapMode && !isOccupied
                        ? AppColors.textPrimary.withValues(alpha: 0.45)
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.bed_rounded,
                  size: 22,
                  color: swapMode && !isOccupied
                      ? iconColor.withValues(alpha: 0.45)
                      : iconColor,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    patientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: swapMode && !isOccupied
                          ? AppColors.textPrimary.withValues(alpha: 0.4)
                          : AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (borderWidth > 0) {
      row = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: row,
      );
    }

    return row;
  }
}

class _SelectionBadge extends StatelessWidget {
  const _SelectionBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}
