import 'package:bounce/bounce.dart';
import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';

String bedOccupancyLookupKey(int? groupId, String bedVariant) {
  final g = groupId?.toString() ?? 'null';
  return '$g::$bedVariant';
}

bool _isBedLabelOccupied(Set<String> occupied, String bedLabel) {
  if (occupied.contains(bedLabel)) return true;
  final n = int.tryParse(bedLabel);
  if (n != null && occupied.contains('$n')) return true;
  return false;
}

int? _lookupAdmissionId(
  Map<String, int> map,
  int? groupId,
  String bedLabel,
) {
  final direct = map[bedOccupancyLookupKey(groupId, bedLabel)];
  if (direct != null) return direct;
  final n = int.tryParse(bedLabel);
  if (n != null) return map[bedOccupancyLookupKey(groupId, '$n')];
  return null;
}

class HospitalGroupBedCard extends StatelessWidget {
  const HospitalGroupBedCard({
    super.key,
    required this.groupName,
    required this.totalBeds,
    required this.availableBeds,
    required this.groupId,
    required this.occupiedBedLabels,
    required this.admissionIdByBedKey,
    required this.onBedTap,
  });

  final String groupName;
  final int totalBeds;
  final int availableBeds;
  final int? groupId;
  final Set<String> occupiedBedLabels;
  final Map<String, int> admissionIdByBedKey;
  final void Function(
    String bedNumber,
    int? hospitalGroupId,
    int? admissionIdIfOccupied,
  ) onBedTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width - 52;
    final crossAxisCount = (width / 64).floor().clamp(4, 8);

    return Material(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              groupName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${AppTexts.availableBeds}: $availableBeds · ${AppTexts.totalBeds}: $totalBeds',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            if (totalBeds <= 0)
              Text(
                AppTexts.noBedsInGroup,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else
              GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.72,
                ),
                itemCount: totalBeds,
                itemBuilder: (context, index) {
                  final bedLabel = '${index + 1}';
                  final isOccupied =
                      _isBedLabelOccupied(occupiedBedLabels, bedLabel);
                  final isAvailable = !isOccupied;
                  final admissionIdIfOccupied = isOccupied
                      ? _lookupAdmissionId(
                          admissionIdByBedKey,
                          groupId,
                          bedLabel,
                        )
                      : null;
                  final bg = isAvailable
                      ? AppColors.success.withValues(alpha: 0.14)
                      : AppColors.error.withValues(alpha: 0.14);
                  final iconColor = isAvailable
                      ? AppColors.success
                      : AppColors.error;
                  final labelColor =
                      isAvailable ? AppColors.primary : AppColors.error;
                  return Material(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                    child: Bounce(
                      onTap: () {
                        if (isOccupied && admissionIdIfOccupied == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not open admission for this bed.',
                              ),
                            ),
                          );
                          return;
                        }
                        onBedTap(bedLabel, groupId, admissionIdIfOccupied);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bed_rounded,
                              size: 32,
                              color: iconColor,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bedLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: labelColor,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
