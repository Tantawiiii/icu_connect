import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';

class AdmissionDetailsSectionContainer extends StatelessWidget {
  const AdmissionDetailsSectionContainer({
    super.key,
    required this.title,
    required this.child,
    this.headerAction,
  });

  final String title;
  final Widget child;
  final Widget? headerAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (headerAction != null) headerAction!,
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
