import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/widgets/list_error_view.dart';
import 'package:icu_connect/core/widgets/status_badge.dart';

import '../../../superAdmin/hospitals/models/hospital_registration_request_model.dart';
import '../cubit/doctor_hospital_requests_cubit.dart';
import '../cubit/doctor_hospital_requests_state.dart';
import '../repository/doctor_hospitals_repository.dart';

class DoctorHospitalRequestsScreen extends StatelessWidget {
  const DoctorHospitalRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DoctorHospitalRequestsCubit(const DoctorHospitalsRepository())
            ..load(),
      child: const _DoctorHospitalRequestsView(),
    );
  }
}

class _DoctorHospitalRequestsView extends StatelessWidget {
  const _DoctorHospitalRequestsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          AppTexts.myHospitalRequests,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
            onPressed: () =>
                context.read<DoctorHospitalRequestsCubit>().refresh(),
          ),
        ],
      ),
      body:
          BlocBuilder<DoctorHospitalRequestsCubit, DoctorHospitalRequestsState>(
            builder: (context, state) {
              if (state is DoctorHospitalRequestsLoading ||
                  state is DoctorHospitalRequestsInitial) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (state is DoctorHospitalRequestsFailure) {
                return ListErrorView(
                  message: state.message,
                  onRetry: () =>
                      context.read<DoctorHospitalRequestsCubit>().refresh(),
                );
              }
              if (state is DoctorHospitalRequestsLoaded) {
                if (state.requests.isEmpty) {
                  return const Center(
                    child: Text(
                      AppTexts.noHospitalRequests,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () =>
                      context.read<DoctorHospitalRequestsCubit>().refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.requests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) =>
                        _RequestCard(request: state.requests[index]),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final HospitalRegistrationRequest request;

  String get _statusLabel {
    if (request.isAccepted) return AppTexts.hospitalRequestStatusAccepted;
    if (request.isRejected) return AppTexts.hospitalRequestStatusRejected;
    return AppTexts.hospitalRequestStatusPending;
  }

  Color get _statusColor {
    if (request.isAccepted) return AppColors.success;
    if (request.isRejected) return AppColors.error;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withAlpha(20),
                  child: const Icon(
                    Icons.local_hospital_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              request.location,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                StatusBadge(label: _statusLabel, color: _statusColor),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 12),
            Row(
              children: [
                _BedStat(
                  label: AppTexts.totalBeds,
                  value: request.totalBeds,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 16),
                _BedStat(
                  label: AppTexts.availableBeds,
                  value: request.availableBeds,
                  color: AppColors.success,
                ),
                const SizedBox(width: 16),
                _BedStat(
                  label: AppTexts.hospitalGroupsSummary,
                  value: request.groups.length,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            if (request.groups.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...request.groups.map(
                (g) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${g.name}: ${g.availableBeds}/${g.totalBeds} beds',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BedStat extends StatelessWidget {
  const _BedStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
