import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';

class AdmissionFormSectionTitle extends StatelessWidget {
  const AdmissionFormSectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
