import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';

class AdmissionDetailsEmptyHint extends StatelessWidget {
  const AdmissionDetailsEmptyHint(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
