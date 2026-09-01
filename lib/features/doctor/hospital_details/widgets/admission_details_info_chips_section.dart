import 'package:flutter/material.dart';

import 'admission_details_meta_chip.dart';
import 'admission_details_section_container.dart';

/// One label/value/icon entry rendered by [AdmissionDetailsInfoChipsSection].
class AdmissionDetailsInfoChip {
  const AdmissionDetailsInfoChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

/// A titled section rendering a wrapped row of small label/value chips —
/// used for the admission's "Doctor" and "Ward / Group" summary blocks.
class AdmissionDetailsInfoChipsSection extends StatelessWidget {
  const AdmissionDetailsInfoChipsSection({
    super.key,
    required this.title,
    required this.chips,
  });

  final String title;
  final List<AdmissionDetailsInfoChip> chips;

  @override
  Widget build(BuildContext context) {
    return AdmissionDetailsSectionContainer(
      title: title,
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        children: chips
            .map(
              (c) => AdmissionDetailsMetaChip(
                label: c.label,
                value: c.value,
                icon: c.icon,
              ),
            )
            .toList(),
      ),
    );
  }
}
