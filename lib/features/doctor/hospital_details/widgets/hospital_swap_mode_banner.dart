import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/widgets/app_button.dart';

import '../models/swap_bed_selection.dart';

String swapBedLocationLabel(SwapBedSelection selection) {
  final bed = '${AppTexts.bedLabel} ${selection.bedLabel}';
  if (selection.groupName.isEmpty) return bed;
  return '${selection.groupName} · $bed';
}

class HospitalSwapModeBanner extends StatelessWidget {
  const HospitalSwapModeBanner({
    super.key,
    required this.first,
    required this.second,
    required this.onCancel,
    this.onReview,
    this.showCrossGroupHint = false,
  });

  final SwapBedSelection? first;
  final SwapBedSelection? second;
  final VoidCallback onCancel;
  final VoidCallback? onReview;
  final bool showCrossGroupHint;

  @override
  Widget build(BuildContext context) {
    final stepText = first == null
        ? AppTexts.swapBedsSelectFirst
        : second == null
            ? AppTexts.swapBedsSelectSecond
            : AppTexts.swapBedsConfirmTitle;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  stepText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
              TextButton(
                onPressed: onCancel,
                child: Text(
                  AppTexts.cancel,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (showCrossGroupHint) ...[
            const SizedBox(height: 8),
            Text(
              AppTexts.swapBedsSwitchGroupHint,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary.withValues(alpha: 0.95),
                height: 1.3,
              ),
            ),
          ],
          if (first != null) ...[
            const SizedBox(height: 10),
            if (second != null &&
                first!.groupId != null &&
                second!.groupId != null &&
                first!.groupId != second!.groupId)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  AppTexts.swapBedsCrossGroupNote,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary.withValues(alpha: 0.9),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: _HospitalMiniSwapChip(
                    label: swapBedLocationLabel(first!),
                    subtitle: first!.patientName,
                    color: AppColors.primary,
                  ),
                ),
                if (second != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                  Expanded(
                    child: _HospitalMiniSwapChip(
                      label: swapBedLocationLabel(second!),
                      subtitle: second!.patientName,
                      color: const Color(0xFFFF9800),
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (onReview != null) ...[
            const SizedBox(height: 10),
            AppButton(
              label: AppTexts.confirmSwap,
              height: 44,
              borderRadius: 22,
              onPressed: onReview,
            ),
          ],
        ],
      ),
    );
  }
}

class _HospitalMiniSwapChip extends StatelessWidget {
  const _HospitalMiniSwapChip({
    required this.label,
    required this.subtitle,
    required this.color,
  });

  final String label;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
