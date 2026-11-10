import 'package:flutter/material.dart';

/// A small rounded, colored label used across list/detail screens to show
/// short status text (e.g. role, active/inactive, deleted).
///
/// Consolidates what used to be near-identical `_Badge`/`_Chip`/`_StatusBadge`
/// private widgets duplicated across several list screens.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
