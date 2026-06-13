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

int? lookupAdmissionId(
  Map<String, int> map,
  int? groupId,
  String bedLabel,
) {
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
  ) onBedTap;

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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
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
  ) onBedTap;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final isOccupied = isBedLabelOccupied(occupiedBedLabels, bedLabel);
    final admissionIdIfOccupied = isOccupied
        ? lookupAdmissionId(admissionIdByBedKey, groupId, bedLabel)
        : null;
    final patientName =
        lookupPatientName(patientNameByBedKey, groupId, bedLabel);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: Bounce(
        onTap: () {
          if (isOccupied && admissionIdIfOccupied == null) {
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
              Text(
                bedLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.bed_rounded, size: 22, color: iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  patientName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
