import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
import '../../login/models/admin_model.dart';
import '../cubit/admin_profile_cubit.dart';
import '../cubit/admin_profile_state.dart';
import '../repository/admin_profile_repository.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminProfileCubit(AdminProfileRepository())..fetchProfile(),
      child: const _AdminProfileView(),
    );
  }
}

class _AdminProfileView extends StatelessWidget {
  const _AdminProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          AppTexts.myProfile,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: () =>
                context.read<AdminProfileCubit>().fetchProfile(),
          ),
        ],
      ),
      body: BlocBuilder<AdminProfileCubit, AdminProfileState>(
        builder: (context, state) {
          return switch (state) {
            AdminProfileInitial() || AdminProfileLoading() => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            AdminProfileFailure(:final message) => _ErrorView(
                message: message,
                onRetry: () =>
                    context.read<AdminProfileCubit>().fetchProfile(),
              ),
            AdminProfileSuccess(:final profile) => _ProfileBody(admin: profile),
          };
        },
      ),
    );
  }
}

// ── Profile body ─────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.admin});

  final AdminModel admin;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _ProfileHeader(admin: admin),
          const SizedBox(height: 24),
          _ProfileInfoCard(admin: admin),
        ],
      ),
    );
  }
}

// ── Profile header (avatar + name + role) ────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.admin});

  final AdminModel admin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: Colors.white24,
            child: Text(
              admin.name.isNotEmpty ? admin.name[0].toUpperCase() : 'A',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            admin.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              admin.role.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                admin.isActive
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                color: admin.isActive ? Colors.greenAccent : Colors.redAccent,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                admin.isActive ? AppTexts.active : AppTexts.inactive,
                style: TextStyle(
                  color:
                      admin.isActive ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({required this.admin});

  final AdminModel admin;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.person_outline,
              label: AppTexts.name,
              value: admin.name,
            ),
            _InfoRow(
              icon: Icons.email_outlined,
              label: AppTexts.emailLabel,
              value: admin.email,
            ),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: AppTexts.phone,
              value: admin.phone.isNotEmpty ? admin.phone : AppTexts.notAvailable,
            ),
            _InfoRow(
              icon: Icons.access_time_outlined,
              label: AppTexts.lastLogin,
              value: admin.lastLoginAt != null
                  ? _formatDate(admin.lastLoginAt!)
                  : AppTexts.notAvailable,
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
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
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
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
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

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
