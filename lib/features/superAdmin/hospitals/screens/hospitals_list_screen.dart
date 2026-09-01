import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_texts.dart';
import '../../../../core/widgets/confirm_action_dialog.dart';
import '../../../../core/widgets/list_error_view.dart';
import '../../../../core/widgets/list_search_field.dart';
import '../../../../core/widgets/paginated_list_footer.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../admins/models/pagination_model.dart';
import '../cubit/hospitals_cubit.dart';
import '../cubit/hospitals_state.dart';
import '../models/hospital_model.dart';
import '../widgets/hospital_requests_tab.dart';
import 'hospital_form_screen.dart';

class HospitalsListScreen extends StatelessWidget {
  const HospitalsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HospitalsCubit()..fetchHospitals(),
      child: const _HospitalsListView(),
    );
  }
}

List<HospitalModel> _filterHospitals(
  List<HospitalModel> hospitals,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return hospitals;
  return hospitals.where((h) {
    if (h.name.toLowerCase().contains(q)) return true;
    if (h.location.toLowerCase().contains(q)) return true;
    return false;
  }).toList();
}

class _HospitalsListView extends StatefulWidget {
  const _HospitalsListView();

  @override
  State<_HospitalsListView> createState() => _HospitalsListViewState();
}

class _HospitalsListViewState extends State<_HospitalsListView>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch() {
    setState(() => _searchQuery = _searchController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(AppTexts.hospitalsLabel),
        titleTextStyle: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 18),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xCCFFFFFF),
          tabs: const [
            Tab(text: AppTexts.hospitalsLabel),
            Tab(text: AppTexts.hospitalRequestsTab),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
            onPressed: () {
              if (_tabController.index == 0) {
                final state = context.read<HospitalsCubit>().state;
                final page = state is HospitalsLoaded
                    ? state.pagination.currentPage
                    : 1;
                context.read<HospitalsCubit>().fetchHospitals(page: page);
              }
            },
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.local_hospital_outlined),
              label: const Text(AppTexts.addHospital),
              onPressed: () => _openForm(context, hospital: null),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  12,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: ListSearchField(
                  controller: _searchController,
                  hintText: 'Search hospitals',
                  onSubmitted: (_) => _applySearch(),
                  onClear: _applySearch,
                ),
              ),
              Expanded(
                child: BlocConsumer<HospitalsCubit, HospitalsState>(
                  listener: (context, state) {
                    if (state is HospitalsActionSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                    if (state is HospitalsActionFailure) {
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
                    if (state is HospitalsLoading ||
                        state is HospitalsInitial) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }
                    if (state is HospitalsFailure) {
                      return ListErrorView(
                        message: state.message,
                        onRetry: () => context
                            .read<HospitalsCubit>()
                            .fetchHospitals(page: 1),
                      );
                    }
                    if (state is HospitalsActionLoading) {
                      return Stack(
                        children: [
                          _HospitalsList(
                            hospitals: state.hospitals,
                            pagination: state.pagination,
                            searchQuery: _searchQuery,
                          ),
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
                    if (state is HospitalsLoaded) {
                      return _HospitalsList(
                        hospitals: state.hospitals,
                        pagination: state.pagination,
                        searchQuery: _searchQuery,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
          const HospitalRequestsTab(),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, {required HospitalModel? hospital}) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => HospitalFormScreen(hospital: hospital),
          ),
        )
        .then((_) {
          if (!context.mounted) return;
          final state = context.read<HospitalsCubit>().state;
          final page = state is HospitalsLoaded
              ? state.pagination.currentPage
              : 1;
          context.read<HospitalsCubit>().fetchHospitals(page: page);
        });
  }
}

// ── List ─────────────────────────────────────────────────────────────────────

class _HospitalsList extends StatelessWidget {
  const _HospitalsList({
    required this.hospitals,
    required this.pagination,
    required this.searchQuery,
  });

  final List<HospitalModel> hospitals;
  final PaginationModel pagination;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    if (hospitals.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_hospital_outlined,
              size: 56,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 12),
            Text(
              'No hospitals found',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    final filtered = _filterHospitals(hospitals, searchQuery);
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<HospitalsCubit>().fetchHospitals(
        page: pagination.currentPage,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: filtered.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Showing ${pagination.from}-${pagination.to} '
                'of ${pagination.total} hospitals',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          }
          if (index == filtered.length + 1) {
            final isFirst = pagination.currentPage <= 1;
            final isLast = pagination.currentPage >= pagination.lastPage;
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: PaginatedListFooter(
                currentPage: pagination.currentPage,
                lastPage: pagination.lastPage,
                onPrevious: isFirst
                    ? null
                    : () => context.read<HospitalsCubit>().fetchHospitals(
                        page: pagination.currentPage - 1,
                      ),
                onNext: isLast
                    ? null
                    : () => context.read<HospitalsCubit>().fetchHospitals(
                        page: pagination.currentPage + 1,
                      ),
              ),
            );
          }
          return _HospitalCard(hospital: filtered[index - 1]);
        },
      ),
    );
  }
}

// ── Hospital card ─────────────────────────────────────────────────────────────

class _HospitalCard extends StatelessWidget {
  const _HospitalCard({required this.hospital});

  final HospitalModel hospital;

  @override
  Widget build(BuildContext context) {
    final bool deleted = hospital.isDeleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: deleted
                          ? AppColors.error.withAlpha(25)
                          : AppColors.primary.withAlpha(20),
                      child: Icon(
                        Icons.local_hospital_outlined,
                        color: deleted ? AppColors.error : AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hospital.name,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: deleted
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                  decoration: deleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
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
                                  hospital.location,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (deleted)
                      const StatusBadge(
                        label: AppTexts.deleted,
                        color: AppColors.error,
                      ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 12),

                // Beds row
                Row(
                  children: [
                    _BedStat(
                      icon: Icons.bed_outlined,
                      label: AppTexts.totalBeds,
                      value: hospital.totalBeds,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _BedStat(
                      icon: Icons.check_circle_outline,
                      label: AppTexts.availableBeds,
                      value: hospital.availableBeds,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _BedStat(
                      icon: Icons.person_outlined,
                      label: AppTexts.occupiedBeds,
                      value: hospital.occupiedBeds,
                      color: AppColors.error,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Occupancy bar
                _OccupancyBar(rate: hospital.occupancyRate),

                const SizedBox(height: 10),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: deleted
                      ? [
                          _ActionButton(
                            icon: Icons.restore_outlined,
                            label: AppTexts.restoreHospital,
                            color: AppColors.success,
                            onTap: () => _confirmRestore(context),
                          ),
                        ]
                      : [
                          _ActionButton(
                            icon: Icons.edit_outlined,
                            label: AppTexts.editHospital,
                            color: AppColors.accent,
                            onTap: () => _openEdit(context),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _ActionButton(
                            icon: Icons.delete_outline,
                            label: AppTexts.deleteHospital,
                            color: AppColors.error,
                            onTap: () => _confirmDelete(context),
                          ),
                        ],
                ),
              ],
            ),
          ),

          // Deleted overlay tint
          if (deleted)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(color: AppColors.error.withAlpha(10)),
              ),
            ),
        ],
      ),
    );
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => HospitalFormScreen(hospital: hospital),
          ),
        )
        .then((_) {
          if (!context.mounted) return;
          final state = context.read<HospitalsCubit>().state;
          final page = state is HospitalsLoaded
              ? state.pagination.currentPage
              : 1;
          context.read<HospitalsCubit>().fetchHospitals(page: page);
        });
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: AppTexts.deleteHospital,
      message: AppTexts.deleteHospitalConfirmation,
      confirmLabel: AppTexts.deleteHospital,
    );
    if (confirmed && context.mounted) {
      context.read<HospitalsCubit>().deleteHospital(hospital.id);
    }
  }

  Future<void> _confirmRestore(BuildContext context) async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: AppTexts.restoreHospital,
      message: AppTexts.restoreHospitalConfirmation,
      confirmLabel: AppTexts.restoreHospital,
      isDestructive: false,
    );
    if (confirmed && context.mounted) {
      context.read<HospitalsCubit>().restoreHospital(hospital.id);
    }
  }
}

// ── Bed stat ──────────────────────────────────────────────────────────────────

class _BedStat extends StatelessWidget {
  const _BedStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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

// ── Occupancy progress bar ────────────────────────────────────────────────────

class _OccupancyBar extends StatelessWidget {
  const _OccupancyBar({required this.rate});

  final double rate;

  @override
  Widget build(BuildContext context) {
    final Color barColor = rate < 0.5
        ? AppColors.success
        : rate < 0.8
        ? const Color(0xFFF59E0B)
        : AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Occupancy',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            Text(
              '${(rate * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                color: barColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: rate,
            minHeight: 6,
            backgroundColor: const Color(0xFFEEEEEE),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

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
