import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';

import 'hospital_stat_chip.dart';

class HospitalGroupStatsRow extends StatelessWidget {
  const HospitalGroupStatsRow({
    super.key,
    required this.totalBeds,
    required this.availableBeds,
    required this.onDoctorsTap,
  });

  final int totalBeds;
  final int availableBeds;
  final VoidCallback onDoctorsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HospitalStatChip(label: '${AppTexts.totalBedsShort} : $totalBeds'),
        const SizedBox(width: 8),
        HospitalStatChip(
          label: '${AppTexts.availableBedsShort} : $availableBeds',
        ),
        const Spacer(),
        Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(999),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onDoctorsTap,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Text(
                AppTexts.viewHospitalDoctors,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
