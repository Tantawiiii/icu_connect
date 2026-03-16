import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/constants/app_colors.dart';


import '../../auth/screens/login_screen.dart';
import '../../profile/screens/profile_screen.dart';

class SideDrawer extends StatelessWidget {
  const SideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                'Dr. Name', // Placeholder
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Doctor ID'),
            ),
            const Divider(),

            // Menu Items
            _buildDrawerItem(context, AppTexts.profile, Icons.person_outline, onTap: () {
               Navigator.pop(context); // Close drawer first
               Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }),
            _buildDrawerItem(context, AppTexts.statistics, Icons.bar_chart),
            _buildDrawerItem(context, AppTexts.aboutUs, Icons.info_outline),
            _buildDrawerItem(context, AppTexts.reportProblem, Icons.report_problem_outlined),
            _buildDrawerItem(context, AppTexts.setting, Icons.settings_outlined),
            _buildDrawerItem(context, AppTexts.trash, Icons.delete_outline),
            
            const Spacer(),
            
            // Logout
            _buildDrawerItem(context, AppTexts.logOut, Icons.logout, onTap: () {
               Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      onTap: onTap ?? () {
        // Handle navigation or other actions
        Navigator.pop(context); // Close drawer
      },
    );
  }
}
