import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/token_storage.dart';
import '../../../doctor/auth/login/screens/login_screen.dart';
import '../../login/cubit/admin_login_cubit.dart';
import '../../login/models/admin_model.dart';
import '../cubit/admin_dashboard_cubit.dart';
import '../widgets/admin_dashboard_section.dart';
import '../widgets/quick_actions.dart';
import '../widgets/welcome_banner.dart';

class SuperAdminHomeScreen extends StatelessWidget {
  const SuperAdminHomeScreen({super.key, required this.admin});

  final AdminModel admin;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminDashboardCubit()..fetchDashboard(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text(
            AppTexts.superAdmin,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: AppTexts.logOut,
              onPressed: () => _confirmLogout(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WelcomeBanner(admin: admin),
              const SizedBox(height: 24),
              const AdminDashboardSection(),
              const SizedBox(height: 24),
              const _SectionTitle(AppTexts.quickActions),
              const SizedBox(height: 12),
              const QuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppTexts.logOut),
        content: const Text(AppTexts.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppTexts.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await TokenStorage.instance.clearAll();
              ApiClient.reset();
              if (!context.mounted) return;
              context.read<AdminLoginCubit>().reset();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: const Text(AppTexts.logOut),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}
