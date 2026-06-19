import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/core/widgets/app_button.dart';

import '../models/swap_bed_selection.dart';
import '../repository/hospital_admissions_repository.dart';

Future<bool> showSwapBedsConfirmSheet({
  required BuildContext context,
  required SwapBedSelection first,
  required SwapBedSelection second,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SwapBedsConfirmSheet(first: first, second: second),
  );
  return result == true;
}

class _SwapBedsConfirmSheet extends StatefulWidget {
  const _SwapBedsConfirmSheet({
    required this.first,
    required this.second,
  });

  final SwapBedSelection first;
  final SwapBedSelection second;

  @override
  State<_SwapBedsConfirmSheet> createState() => _SwapBedsConfirmSheetState();
}

class _SwapBedsConfirmSheetState extends State<_SwapBedsConfirmSheet>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _isLoading = true);
    try {
      await const HospitalAdmissionsRepository().swapBeds(
        firstAdmissionId: widget.first.admissionId,
        secondAdmissionId: widget.second.admissionId,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on NetworkException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      setState(() => _isLoading = false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppTexts.swapBedsFailed)),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, 14 + bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppTexts.swapBedsConfirmTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppTexts.swapBedsConfirmMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textSecondary.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(height: 20),
              if (widget.first.groupId != null &&
                  widget.second.groupId != null &&
                  widget.first.groupId != widget.second.groupId)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    AppTexts.swapBedsCrossGroupNote,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _SwapBedPreviewCard(selection: widget.first),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ScaleTransition(
                      scale: _pulse,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          color: AppColors.primary,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _SwapBedPreviewCard(selection: widget.second),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              AppButton(
                label: AppTexts.confirmSwap,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _confirm,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                child: Text(
                  AppTexts.cancel,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w600,
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

class _SwapBedPreviewCard extends StatelessWidget {
  const _SwapBedPreviewCard({required this.selection});

  final SwapBedSelection selection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          if (selection.groupName.isNotEmpty) ...[
            Text(
              selection.groupName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bed_rounded,
                size: 18,
                color: AppColors.primary.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 6),
              Text(
                '${AppTexts.bedLabel} ${selection.bedLabel}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            selection.patientName.isEmpty
                ? AppTexts.notAvailable
                : selection.patientName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
