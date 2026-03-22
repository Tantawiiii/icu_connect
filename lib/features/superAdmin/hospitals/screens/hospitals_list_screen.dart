import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
import '../cubit/hospitals_cubit.dart';
import '../cubit/hospitals_state.dart';
import '../models/hospital_model.dart';
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

class _HospitalsListView extends StatelessWidget {
  const _HospitalsListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          AppTexts.hospitalsLabel,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
            onPressed: () => context.read<HospitalsCubit>().fetchHospitals(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.local_hospital_outlined),
        label: const Text(AppTexts.addHospital),
        onPressed: () => _openForm(context, hospital: null),
      ),
      body: BlocConsumer<HospitalsCubit, HospitalsState>(
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
          if (state is HospitalsLoading || state is HospitalsInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state is HospitalsFailure) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<HospitalsCubit>().fetchHospitals(),
            );
          }
          if (state is HospitalsActionLoading) {
            return Stack(
              children: [
                _HospitalsList(hospitals: state.hospitals),
                const ColoredBox(
                  color: Color(0x55000000),
                  child: Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ],
            );
          }
          if (state is HospitalsLoaded) {
            return _HospitalsList(hospitals: state.hospitals);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _openForm(BuildContext context, {required HospitalModel? hospital}) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => HospitalFormScreen(hospital: hospital),
        ))
        .then((_) {
      if (context.mounted) context.read<HospitalsCubit>().fetchHospitals();
    });
  }
}

// ── List ─────────────────────────────────────────────────────────────────────

class _HospitalsList extends StatelessWidget {
  const _HospitalsList({required this.hospitals});

  final List<HospitalModel> hospitals;

  @override
  Widget build(BuildContext context) {
    if (hospitals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_hospital_outlined,
                size: 56, color: AppColors.secondary),
            SizedBox(height: 12),
            Text('No hospitals found',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<HospitalsCubit>().fetchHospitals(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${hospitals.length} '
              '${hospitals.length == 1 ? 'hospital' : 'hospitals'}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          ...hospitals.map((h) => _HospitalCard(hospital: h)),
        ],
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hospital.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
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
                              const Icon(Icons.location_on_outlined,
                                  size: 13, color: AppColors.textSecondary),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  hospital.location,
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
                    if (deleted)
                      const _Badge(
                          label: AppTexts.deleted, color: AppColors.error),
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
                    const SizedBox(width: 16),
                    _BedStat(
                      icon: Icons.check_circle_outline,
                      label: AppTexts.availableBeds,
                      value: hospital.availableBeds,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 16),
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
                          const SizedBox(width: 8),
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
                child: ColoredBox(
                  color: AppColors.error.withAlpha(10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => HospitalFormScreen(hospital: hospital),
        ))
        .then((_) {
      if (context.mounted) context.read<HospitalsCubit>().fetchHospitals();
    });
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppTexts.deleteHospital),
        content: const Text(AppTexts.deleteHospitalConfirmation),
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
              context.read<HospitalsCubit>().deleteHospital(hospital.id);
            },
            child: const Text(AppTexts.deleteHospital),
          ),
        ],
      ),
    );
  }

  void _confirmRestore(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppTexts.restoreHospital),
        content: const Text(AppTexts.restoreHospitalConfirmation),
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
              context.read<HospitalsCubit>().restoreHospital(hospital.id);
            },
            child: const Text(AppTexts.restoreHospital),
          ),
        ],
      ),
    );
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
                    color: color, fontSize: 10, fontWeight: FontWeight.w600),
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
            const Text('Occupancy',
                style:
                    TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text(
              '${(rate * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                  fontSize: 11,
                  color: barColor,
                  fontWeight: FontWeight.w600),
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
                  color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge ─────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
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
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
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
