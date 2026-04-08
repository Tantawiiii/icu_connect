import 'package:bounce/bounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/widgets/app_text_field.dart';
import 'package:shimmer/shimmer.dart';

import '../../hospital_details/screens/hospital_details_screen.dart';
import '../cubit/doctor_hospitals_cubit.dart';
import '../cubit/doctor_hospitals_state.dart';
import '../models/doctor_hospital.dart';


const double _hospitalCardMinHeight = 120;

List<DoctorHospital> _filterHospitals(List<DoctorHospital> hospitals, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return hospitals;
  return hospitals.where((h) {
    if (h.name.toLowerCase().contains(q)) return true;
    final loc = h.location?.toLowerCase() ?? '';
    return loc.contains(q);
  }).toList();
}

class DoctorHospitalsSection extends StatefulWidget {
  const DoctorHospitalsSection({super.key});

  @override
  State<DoctorHospitalsSection> createState() => _DoctorHospitalsSectionState();
}

class _DoctorHospitalsSectionState extends State<DoctorHospitalsSection> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            AppTexts.yourHospitals,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        AppTextField(
          controller: _searchController,
          hintText: AppTexts.searchHospitalsHint,
          textInputAction: TextInputAction.search,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () => _searchController.clear(),
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: BlocBuilder<DoctorHospitalsCubit, DoctorHospitalsState>(
            builder: (context, state) {
              return switch (state) {
                DoctorHospitalsInitial() ||
                DoctorHospitalsLoading() =>
                  const _HospitalsShimmerList(),
                DoctorHospitalsLoaded(:final hospitals) =>
                  _HospitalsListBody(
                    hospitals: hospitals,
                    query: _searchController.text,
                  ),
                DoctorHospitalsFailure(:final message) => _HospitalsError(
                    message: message,
                    onRetry: () =>
                        context.read<DoctorHospitalsCubit>().refresh(),
                  ),
              };
            },
          ),
        ),
      ],
    );
  }
}

class _HospitalsShimmerList extends StatelessWidget {
  const _HospitalsShimmerList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 4),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.border,
        highlightColor: AppColors.surface,
        child: Container(
          width: double.infinity,
          height: _hospitalCardMinHeight,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
        ),
      ),
    );
  }
}

class _HospitalsError extends StatelessWidget {
  const _HospitalsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
        Column(
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
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
      ],
    );
  }
}

class _HospitalsListBody extends StatelessWidget {
  const _HospitalsListBody({
    required this.hospitals,
    required this.query,
  });

  final List<DoctorHospital> hospitals;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (hospitals.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
          Center(
            child: Text(
              AppTexts.noHospitalsAvailable,
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    }

    final filtered = _filterHospitals(hospitals, query);
    if (filtered.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
          Center(
            child: Text(
              AppTexts.hospitalsSearchEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 4),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _HospitalCard(hospital: filtered[index]),
    );
  }
}

class _HospitalCard extends StatelessWidget {
  const _HospitalCard({required this.hospital});

  final DoctorHospital hospital;

  String get _statusLabel {
    if (hospital.isUnlocked) return AppTexts.hospitalAccessGranted;
    final s = hospital.userStatus.status?.toLowerCase();
    if (s == 'pending') return AppTexts.hospitalStatusPending;
    if (s == 'rejected') return AppTexts.hospitalStatusRejected;
    if (hospital.userStatus.canRequest) {
      return AppTexts.hospitalStatusRequestAccess;
    }
    return AppTexts.hospitalStatusNotMember;
  }

  Color get _statusColor {
    if (hospital.isUnlocked) return AppColors.success;
    final s = hospital.userStatus.status?.toLowerCase();
    if (s == 'pending') return AppColors.warning;
    if (s == 'rejected') return AppColors.error;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = hospital.isUnlocked;

    return SizedBox(
      height: _hospitalCardMinHeight,
      width: double.infinity,
      child: Material(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Bounce(
          onTap: unlocked
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HospitalDetailsScreen(hospital: hospital),
                    ),
                  );
                }
              : null,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            hospital.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (unlocked)
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.success,
                            size: 22,
                          ),
                      ],
                    ),
                    if (hospital.location != null &&
                        hospital.location!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        hospital.location!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.25,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      '${AppTexts.hospitalBedsSummary}: '
                      '${hospital.totalBeds}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              if (!unlocked)
                _LockOverlay(statusLabel: _statusLabel, statusColor: _statusColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockOverlay extends StatelessWidget {
  const _LockOverlay({
    required this.statusLabel,
    required this.statusColor,
  });

  final String statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.28),
                    AppColors.primary.withValues(alpha: 0.12),
                  ],
                ),
              ),
            ),
            Container(
              color: Colors.white.withValues(alpha: 0.45),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.08),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 26,
                      color: AppColors.primary.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
