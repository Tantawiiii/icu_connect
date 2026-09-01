import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_texts.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/widgets/confirm_action_dialog.dart';
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
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text(AppTexts.superAdmin),
          titleTextStyle: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 18),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: AppTexts.logOut,
              onPressed: () => _confirmLogout(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WelcomeBanner(admin: admin),
              const SizedBox(height: AppSpacing.lg),
              const AdminDashboardSection(),
              const SizedBox(height: AppSpacing.lg),
              const _SectionTitle(AppTexts.quickActions),
              const SizedBox(height: AppSpacing.sm),
              const QuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: AppTexts.logOut,
      message: AppTexts.logoutConfirmMessage,
      confirmLabel: AppTexts.logOut,
    );
    if (!confirmed || !context.mounted) return;
    await TokenStorage.instance.clearAll();
    ApiClient.reset();
    if (!context.mounted) return;
    context.read<AdminLoginCubit>().reset();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleSmall);
  }
}
