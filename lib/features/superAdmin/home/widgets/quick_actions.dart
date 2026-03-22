import 'package:bounce/bounce.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
import '../../admins/screens/admins_list_screen.dart';
import '../../hospitals/screens/hospitals_list_screen.dart';
import '../../users/screens/users_list_screen.dart';
import '../../patients/screens/patients_list_screen.dart';
import '../../labs/screens/labs_titles_list_screen.dart';
import '../../vitals/screens/vitals_titles_list_screen.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _ActionTile(
          icon: Icons.people_outline,
          label: AppTexts.superAdmins,
          color: AppColors.primary,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminsListScreen()),
          ),
        ),
        _ActionTile(
          icon: Icons.local_hospital_outlined,
          label: AppTexts.hospitalsLabel,
          color: AppColors.accent,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HospitalsListScreen()),
          ),
        ),
        _ActionTile(
          icon: Icons.medical_services_outlined,
          label: AppTexts.usersLabel,
          color: Colors.indigo,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const UsersListScreen()),
          ),
        ),
        _ActionTile(
          icon: Icons.personal_injury_outlined,
          label: AppTexts.patientsLabel,
          color: Colors.pink,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PatientsListScreen()),
          ),
        ),
        _ActionTile(
          icon: Icons.science_outlined,
          label: AppTexts.labsLabel,
          color: Colors.deepPurple,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LabsTitlesListScreen()),
          ),
        ),
        _ActionTile(
          icon: Icons.monitor_heart_outlined,
          label: AppTexts.vitalsLabel,
          color: Colors.redAccent,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const VitalsTitlesListScreen()),
          ),
        ),
        _ActionTile(
          icon: Icons.bar_chart_outlined,
          label: AppTexts.statistics,
          color: Colors.teal,
        ),
        _ActionTile(
          icon: Icons.dashboard_outlined,
          label: AppTexts.dashboardLabel,
          color: Colors.deepOrange,
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Bounce(
      onTap: onTap != null ? () => onTap!() : null,
      child: AnimatedOpacity(
        opacity: onTap != null ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(51)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
