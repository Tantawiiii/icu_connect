import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/network/api_client.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/core/network/token_storage.dart';

import '../../auth/login/screens/login_screen.dart';
import '../../patients/screens/patient_list_screen.dart';
import '../../profile/repository/doctor_profile_repository.dart';
import '../../profile/screens/profile_screen.dart';
import '../../session/doctor_session_display.dart';

class SideDrawer extends StatelessWidget {
  const SideDrawer({super.key});

  static Future<void> fetchAndApplyProfile() async {
    try {
      final profile = await const DoctorProfileRepository().fetchProfile();
      await DoctorSessionDisplay.apply(name: profile.name, role: profile.role);
    } on NetworkException {
      // Keep existing cached header if the request fails.
    } catch (_) {
      // Same: ignore unexpected errors for a non-blocking drawer header.
    }
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static String _formatRoleLabel(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return AppTexts.notAvailable;
    return t.length == 1
        ? t.toUpperCase()
        : '${t[0].toUpperCase()}${t.substring(1).toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            ValueListenableBuilder<String>(
              valueListenable: DoctorSessionDisplay.name,
              builder: (context, displayName, _) {
                return ValueListenableBuilder<String>(
                  valueListenable: DoctorSessionDisplay.role,
                  builder: (context, displayRole, _) {
                    final name = displayName.trim().isEmpty
                        ? AppTexts.notAvailable
                        : displayName.trim();
                    final roleLine =
                        '${AppTexts.roleLabel}: ${_formatRoleLabel(displayRole)}';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Text(
                          _initials(displayName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        roleLine,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                );
              },
            ),
            const Divider(),
            _buildDrawerItem(
              context,
              AppTexts.profile,
              Icons.person_outline,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            _buildDrawerItem(
              context,
              AppTexts.patientsLabel,
              Icons.people_outline,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PatientListScreen()),
                );
              },
            ),
            // _buildDrawerItem(context, AppTexts.statistics, Icons.bar_chart),
            // _buildDrawerItem(context, AppTexts.aboutUs, Icons.info_outline),
            // _buildDrawerItem(
            //   context,
            //   AppTexts.reportProblem,
            //   Icons.report_problem_outlined,
            // ),
            // _buildDrawerItem(
            //   context,
            //   AppTexts.setting,
            //   Icons.settings_outlined,
            // ),
            // _buildDrawerItem(context, AppTexts.trash, Icons.delete_outline),

            const Spacer(),

            // Logout
            _buildDrawerItem(
              context,
              AppTexts.logOut,
              Icons.logout,
              onTap: () => _logout(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final accessToken = await TokenStorage.instance.getAccessToken();
    final refreshToken = await TokenStorage.instance.getRefreshToken();

    debugPrint(
      '[Auth] before logout - access token exists: '
      '${accessToken != null && accessToken.isNotEmpty}',
    );
    debugPrint(
      '[Auth] before logout - refresh token exists: '
      '${refreshToken != null && refreshToken.isNotEmpty}',
    );
    if (accessToken != null && accessToken.isNotEmpty) {
      debugPrint('[Auth] access token: $accessToken');
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      debugPrint('[Auth] refresh token: $refreshToken');
    }

    await TokenStorage.instance.clearAll();
    DoctorSessionDisplay.resetNotifiers();
    ApiClient.reset();

    final accessAfter = await TokenStorage.instance.getAccessToken();
    final refreshAfter = await TokenStorage.instance.getRefreshToken();
    debugPrint(
      '[Auth] after logout - access token exists: '
      '${accessAfter != null && accessAfter.isNotEmpty}',
    );
    debugPrint(
      '[Auth] after logout - refresh token exists: '
      '${refreshAfter != null && refreshAfter.isNotEmpty}',
    );

    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      onTap:
          onTap ??
          () {
            Navigator.pop(context);
          },
    );
  }
}
