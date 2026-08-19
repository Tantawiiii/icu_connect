import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
import '../../../../core/widgets/list_error_view.dart';
import '../../../../core/widgets/paginated_list_footer.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../admins/models/pagination_model.dart';
import '../cubit/hospital_requests_cubit.dart';
import '../cubit/hospital_requests_state.dart';
import '../models/hospital_registration_request_model.dart';

class HospitalRequestsTab extends StatelessWidget {
  const HospitalRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HospitalRequestsCubit()..fetchRequests(),
      child: const _HospitalRequestsTabView(),
    );
  }
}

class _HospitalRequestsTabView extends StatefulWidget {
  const _HospitalRequestsTabView();

  @override
  State<_HospitalRequestsTabView> createState() =>
      _HospitalRequestsTabViewState();
}

class _HospitalRequestsTabViewState extends State<_HospitalRequestsTabView> {
  String? _statusFilter;

  void _setFilter(String? status) {
    setState(() => _statusFilter = status);
    context.read<HospitalRequestsCubit>().fetchRequests(approvalStatus: status);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              _FilterChip(
                label: AppTexts.hospitalRequestsAll,
                selected: _statusFilter == null,
                onTap: () => _setFilter(null),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: AppTexts.hospitalRequestsPending,
                selected: _statusFilter == 'pending',
                onTap: () => _setFilter('pending'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: AppTexts.hospitalRequestsAccepted,
                selected: _statusFilter == 'accepted',
                onTap: () => _setFilter('accepted'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: AppTexts.hospitalRequestsRejected,
                selected: _statusFilter == 'rejected',
                onTap: () => _setFilter('rejected'),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocConsumer<HospitalRequestsCubit, HospitalRequestsState>(
            listener: (context, state) {
              if (state is HospitalRequestsActionSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              if (state is HospitalRequestsActionFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is HospitalRequestsLoading ||
                  state is HospitalRequestsInitial) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (state is HospitalRequestsFailure) {
                return ListErrorView(
                  message: state.message,
                  onRetry: () => context
                      .read<HospitalRequestsCubit>()
                      .fetchRequests(approvalStatus: _statusFilter),
                );
              }
              if (state is HospitalRequestsLoaded ||
                  state is HospitalRequestsActionLoading ||
                  state is HospitalRequestsActionSuccess ||
                  state is HospitalRequestsActionFailure) {
                final loaded = state as HospitalRequestsLoaded;
                final isActionLoading = state is HospitalRequestsActionLoading;
                return Stack(
                  children: [
                    _RequestsList(
                      requests: loaded.requests,
                      pagination: loaded.pagination,
                      statusFilter: _statusFilter,
                    ),
                    if (isActionLoading)
                      const ColoredBox(
                        color: Color(0x55000000),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withAlpha(30),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

class _RequestsList extends StatelessWidget {
  const _RequestsList({
    required this.requests,
    required this.pagination,
    required this.statusFilter,
  });

  final List<HospitalRegistrationRequest> requests;
  final PaginationModel pagination;
  final String? statusFilter;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const Center(
        child: Text(
          AppTexts.noHospitalRequests,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<HospitalRequestsCubit>().fetchRequests(
        approvalStatus: statusFilter,
        page: pagination.currentPage,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: requests.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Showing ${pagination.from}-${pagination.to} '
                'of ${pagination.total} requests',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            );
          }
          if (index == requests.length + 1) {
            final isFirst = pagination.currentPage <= 1;
            final isLast = pagination.currentPage >= pagination.lastPage;
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: PaginatedListFooter(
                currentPage: pagination.currentPage,
                lastPage: pagination.lastPage,
                onPrevious: isFirst
                    ? null
                    : () => context.read<HospitalRequestsCubit>().fetchRequests(
                        approvalStatus: statusFilter,
                        page: pagination.currentPage - 1,
                      ),
                onNext: isLast
                    ? null
                    : () => context.read<HospitalRequestsCubit>().fetchRequests(
                        approvalStatus: statusFilter,
                        page: pagination.currentPage + 1,
                      ),
              ),
            );
          }
          return _RequestCard(request: requests[index - 1]);
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
      margin: const EdgeInsets.only(bottom: 12),
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
                  radius: 22,
                  backgroundColor: AppColors.primary.withAlpha(20),
                  child: const Icon(
                    Icons.local_hospital_outlined,
                    color: AppColors.primary,
                    size: 22,
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
              ],
            ),
            if (request.groups.isNotEmpty) ...[
              const SizedBox(height: 10),
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
            if (request.isPending) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _ActionButton(
                    icon: Icons.check_circle_outline,
                    label: AppTexts.acceptHospitalRequest,
                    color: AppColors.success,
                    onTap: () => _confirmAccept(context),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.cancel_outlined,
                    label: AppTexts.rejectHospitalRequest,
                    color: AppColors.error,
                    onTap: () => _confirmReject(context),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmAccept(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppTexts.acceptHospitalRequest),
        content: const Text(AppTexts.acceptHospitalRequestConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppTexts.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<HospitalRequestsCubit>().acceptRequest(request.id);
            },
            child: const Text(AppTexts.acceptHospitalRequest),
          ),
        ],
      ),
    );
  }

  void _confirmReject(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppTexts.rejectHospitalRequest),
        content: const Text(AppTexts.rejectHospitalRequestConfirmation),
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
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<HospitalRequestsCubit>().rejectRequest(request.id);
            },
            child: const Text(AppTexts.rejectHospitalRequest),
          ),
        ],
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
