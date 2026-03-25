import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
import '../models/hospital_entry.dart';

class HospitalAssignmentRow extends StatelessWidget {
  const HospitalAssignmentRow({
    super.key,
    required this.entry,
    required this.roles,
    required this.statuses,
    required this.onRoleChanged,
    required this.onStatusChanged,
    required this.onRemove,
    required this.isLast,
  });

  final HospitalEntry entry;
  final List<String> roles;
  final List<String> statuses;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onRemove;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final statusOptions = entry.status != null &&
            !statuses.contains(entry.status)
        ? [...statuses, entry.status!]
        : statuses;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Hospital icon
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_hospital_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),

              // Hospital name + role/status pickers
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.hospitalName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonHideUnderline(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlpha(15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.accent.withAlpha(50),
                          ),
                        ),
                        child: DropdownButton<String>(
                          value: roles.contains(entry.role) ? entry.role : roles.first,
                          isDense: true,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          items: roles
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(
                                    r[0].toUpperCase() + r.substring(1),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) onRoleChanged(v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonHideUnderline(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlpha(15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.accent.withAlpha(50),
                          ),
                        ),
                        child: DropdownButton<String>(
                          value: entry.status ?? statusOptions.first,
                          isDense: true,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          items: statusOptions
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    s[0].toUpperCase() + s.substring(1),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) onStatusChanged(v);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Remove button
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                onPressed: onRemove,
                tooltip: AppTexts.remove,
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 14,
            endIndent: 14,
            color: Color(0xFFEEEEEE),
          ),
      ],
    );
  }
}

