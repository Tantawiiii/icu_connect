import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
import '../cubit/admin_dashboard_cubit.dart';
import '../cubit/admin_dashboard_state.dart';
import '../models/admin_dashboard_model.dart';

class AdminDashboardSection extends StatelessWidget {
  const AdminDashboardSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        return switch (state) {
          AdminDashboardInitial() ||
          AdminDashboardLoading() =>
            const _DashboardShimmer(),
          AdminDashboardLoaded(:final data) =>
            _DashboardContent(data: data),
          AdminDashboardFailure(:final message) => _DashboardError(
              message: message,
              onRetry: () =>
                  context.read<AdminDashboardCubit>().fetchDashboard(),
            ),
        };
      },
    );
  }
}

class _DashboardShimmer extends StatelessWidget {
  const _DashboardShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: AppColors.border,
          highlightColor: AppColors.surface,
          child: Container(
            width: 140,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.75,
          children: List.generate(
            8,
            (_) => Shimmer.fromColors(
              baseColor: AppColors.border,
              highlightColor: AppColors.surface,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Shimmer.fromColors(
          baseColor: AppColors.border,
          highlightColor: AppColors.surface,
          child: Container(
            width: 180,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Shimmer.fromColors(
              baseColor: AppColors.border,
              highlightColor: AppColors.surface,
              child: Container(
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text(AppTexts.retry),
          ),
        ],
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data});

  final AdminDashboardData data;

  @override
  Widget build(BuildContext context) {
    final o = data.overview;
    final stats = <_StatItem>[
      _StatItem(
        label: AppTexts.dashboardTotalHospitals,
        value: '${o.totalHospitals}',
        icon: Icons.local_hospital_outlined,
        color: AppColors.accent,
      ),
      _StatItem(
        label: AppTexts.dashboardTotalPatients,
        value: '${o.totalPatients}',
        icon: Icons.personal_injury_outlined,
        color: Colors.pink,
      ),
      _StatItem(
        label: AppTexts.dashboardTotalDoctors,
        value: '${o.totalDoctors}',
        icon: Icons.medical_services_outlined,
        color: Colors.indigo,
      ),
      _StatItem(
        label: AppTexts.dashboardTotalAdmissions,
        value: '${o.totalAdmissions}',
        icon: Icons.event_note_outlined,
        color: Colors.deepPurple,
      ),
      _StatItem(
        label: AppTexts.dashboardActiveAdmissions,
        value: '${o.activeAdmissions}',
        icon: Icons.monitor_heart_outlined,
        color: Colors.redAccent,
      ),
      _StatItem(
        label: AppTexts.totalBeds,
        value: o.totalBeds,
        icon: Icons.hotel_outlined,
        color: AppColors.primary,
      ),
      _StatItem(
        label: AppTexts.availableBeds,
        value: o.availableBeds,
        icon: Icons.event_seat_outlined,
        color: Colors.teal,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(AppTexts.dashboardOverview),
        const SizedBox(height: 12),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.75,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          itemBuilder: (context, i) => _StatCard(item: stats[i]),
        ),
        const SizedBox(height: 24),
        const _SectionTitle(AppTexts.dashboardRecentAdmissions),
        const SizedBox(height: 12),
        if (data.recentAdmissions.isEmpty)
          Text(
            AppTexts.dashboardNoRecentAdmissions,
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          )
        else
          ...data.recentAdmissions.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RecentAdmissionTile(admission: a),
            ),
          ),
      ],
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

class _StatItem {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: item.color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: item.color, size: 24),
              const SizedBox(width: 6),
              Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: item.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Text(
            item.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: item.color.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentAdmissionTile extends StatelessWidget {
  const _RecentAdmissionTile({required this.admission});

  final DashboardRecentAdmission admission;

  @override
  Widget build(BuildContext context) {
    final title = admission.patientName?.trim().isNotEmpty == true
        ? admission.patientName!
        : '${AppTexts.admissionsSection} #${admission.id}';

    final parts = <String>[
      if (admission.hospitalName != null &&
          admission.hospitalName!.trim().isNotEmpty)
        admission.hospitalName!,
      if (admission.status != null && admission.status!.trim().isNotEmpty)
        admission.status!,
      if (admission.bedNumber != null &&
          admission.bedNumber!.trim().isNotEmpty)
        '${AppTexts.bedNo} ${admission.bedNumber}',
    ];

    return Material(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            if (parts.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                parts.join(' · '),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (admission.dateComes != null &&
                admission.dateComes!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                admission.dateComes!,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary.withValues(alpha: 0.85),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
