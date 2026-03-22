import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
import '../../login/models/admin_model.dart';

class AdminInfoCard extends StatelessWidget {
  const AdminInfoCard({super.key, required this.admin});

  final AdminModel admin;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoRow(icon: Icons.person_outline, label: AppTexts.name, value: admin.name),
            _InfoRow(icon: Icons.email_outlined, label: AppTexts.emailLabel, value: admin.email),
            _InfoRow(icon: Icons.phone_outlined, label: AppTexts.phone, value: admin.phone),
            _InfoRow(
              icon: Icons.access_time_outlined,
              label: AppTexts.lastLogin,
              value: admin.lastLoginAt != null
                  ? _formatDate(admin.lastLoginAt!)
                  : AppTexts.notAvailable,
            ),
            _InfoRow(
              icon: admin.isActive
                  ? Icons.check_circle_outline
                  : Icons.cancel_outlined,
              label: AppTexts.status,
              value: admin.isActive ? AppTexts.active : AppTexts.inactive,
              valueColor: admin.isActive ? AppColors.success : AppColors.error,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.secondary),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}
