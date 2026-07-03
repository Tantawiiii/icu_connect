import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/app_text_field.dart';

import '../../../superAdmin/patients/models/patient_admission_models.dart';
import '../../home/models/doctor_hospital.dart';
import '../enums/admission_status.dart';
import '../repository/hospital_admissions_repository.dart';
import '../utils/hospital_bed_occupancy_utils.dart';
import '../widgets/admission_details_formatters.dart';
import 'admission_details_screen.dart';

enum DischargedPatientsFilter { all, improved, die, dama }

enum DischargedDatePeriod {
  lastMonth,
  last3Months,
  lastYear,
  allTime,
}

extension DischargedDatePeriodX on DischargedDatePeriod {
  String get label {
    switch (this) {
      case DischargedDatePeriod.lastMonth:
        return AppTexts.dischargedPeriodLastMonth;
      case DischargedDatePeriod.last3Months:
        return AppTexts.dischargedPeriodLast3Months;
      case DischargedDatePeriod.lastYear:
        return AppTexts.dischargedPeriodLastYear;
      case DischargedDatePeriod.allTime:
        return AppTexts.dischargedPeriodAllTime;
    }
  }

  DateTime? get startDate {
    final now = DateTime.now();
    switch (this) {
      case DischargedDatePeriod.lastMonth:
        return now.subtract(const Duration(days: 30));
      case DischargedDatePeriod.last3Months:
        return now.subtract(const Duration(days: 90));
      case DischargedDatePeriod.lastYear:
        return now.subtract(const Duration(days: 365));
      case DischargedDatePeriod.allTime:
        return null;
    }
  }
}

class DischargedPatientsScreen extends StatefulWidget {
  const DischargedPatientsScreen({super.key, required this.hospital});

  final DoctorHospital hospital;

  @override
  State<DischargedPatientsScreen> createState() =>
      _DischargedPatientsScreenState();
}

class _DischargedPatientsScreenState extends State<DischargedPatientsScreen> {
  static const _repo = HospitalAdmissionsRepository();

  late Future<List<PatientAdmissionModel>> _admissionsFuture;
  final TextEditingController _searchController = TextEditingController();
  DischargedPatientsFilter _filter = DischargedPatientsFilter.all;
  DischargedDatePeriod _period = DischargedDatePeriod.lastMonth;

  @override
  void initState() {
    super.initState();
    _admissionsFuture = _loadAdmissions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<PatientAdmissionModel>> _loadAdmissions() {
    return _repo.listDischargedOutcomeAdmissions(
      hospitalId: widget.hospital.id,
    );
  }

  void _refresh() {
    setState(() => _admissionsFuture = _loadAdmissions());
  }

  DateTime? _outcomeDate(PatientAdmissionModel admission) {
    final status = AdmissionStatus.fromApiValue(admission.status);
    if (status == AdmissionStatus.deceased) {
      return DateTime.tryParse(admission.dateOfDeath ?? '');
    }
    return DateTime.tryParse(admission.dateLeave ?? '') ??
        DateTime.tryParse(admission.updatedAt) ??
        DateTime.tryParse(admission.createdAt);
  }

  List<PatientAdmissionModel> _inPeriod(List<PatientAdmissionModel> all) {
    final start = _period.startDate;
    if (start == null) return all;
    return all.where((admission) {
      final date = _outcomeDate(admission);
      if (date == null) return false;
      return !date.isBefore(start);
    }).toList();
  }

  AdmissionStatus? _filterStatus(DischargedPatientsFilter filter) {
    switch (filter) {
      case DischargedPatientsFilter.all:
        return null;
      case DischargedPatientsFilter.improved:
        return AdmissionStatus.discharged;
      case DischargedPatientsFilter.die:
        return AdmissionStatus.deceased;
      case DischargedPatientsFilter.dama:
        return AdmissionStatus.leavesAma;
    }
  }

  List<PatientAdmissionModel> _applyFilters(List<PatientAdmissionModel> all) {
    final inPeriod = _inPeriod(all);
    final status = _filterStatus(_filter);
    final byStatus = status == null
        ? inPeriod
        : inPeriod
            .where(
              (a) => AdmissionStatus.fromApiValue(a.status) == status,
            )
            .toList();
    return _applySearch(byStatus);
  }

  List<PatientAdmissionModel> _applySearch(
    List<PatientAdmissionModel> admissions,
  ) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return admissions;

    return admissions.where((admission) {
      if (filterAdmissionsBySearch([admission], q).isNotEmpty) return true;

      final nationalId = admission.patient?.nationalId.toLowerCase() ?? '';
      if (nationalId.contains(q)) return true;

      final statusLabel =
          admissionStatusDisplayLabel(admission.status).toLowerCase();
      if (statusLabel.contains(q)) return true;

      if ('${admission.id}'.contains(q)) return true;

      final outcomeDate = _outcomeDate(admission);
      if (outcomeDate != null) {
        final formatted = admissionDetailsFormatDateTime(
          outcomeDate.toIso8601String(),
        ).toLowerCase();
        if (formatted.contains(q)) return true;
      }

      return false;
    }).toList();
  }

  Map<AdmissionStatus, int> _countsByOutcome(
    List<PatientAdmissionModel> inPeriod,
  ) {
    final counts = {
      for (final status in AdmissionStatus.dischargedOutcomes) status: 0,
    };
    for (final admission in inPeriod) {
      final status = AdmissionStatus.fromApiValue(admission.status);
      if (counts.containsKey(status)) {
        counts[status] = counts[status]! + 1;
      }
    }
    return counts;
  }

  String _percent(int part, int total) {
    if (total <= 0) return '0%';
    return '${((part / total) * 100).round()}%';
  }

  String _patientName(PatientAdmissionModel admission) {
    final name = admission.patient?.name.trim();
    if (name != null && name.isNotEmpty) return name;
    return AppTexts.admissionCardTitle(
      admission.id,
      admission.bedNumber.isEmpty
          ? admissionStatusDisplayLabel(admission.status)
          : admission.bedNumber,
    );
  }

  String _outcomeDateLabel(PatientAdmissionModel admission) {
    final date = _outcomeDate(admission);
    if (date == null) return AppTexts.notAvailable;
    return admissionDetailsFormatDateTime(date.toIso8601String());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          AppTexts.dischargedPatients,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<List<PatientAdmissionModel>>(
        future: _admissionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            final message = snapshot.error is NetworkException
                ? (snapshot.error as NetworkException).message
                : 'Failed to load discharged patients.';
            return _DischargedErrorState(message: message, onRetry: _refresh);
          }

          final all = snapshot.data ?? const [];
          final inPeriod = _inPeriod(all);
          final filtered = _applyFilters(all);
          final counts = _countsByOutcome(inPeriod);
          final total = inPeriod.length;
          final hasSearch = _searchController.text.trim().isNotEmpty;

          filtered.sort((a, b) {
            final da = _outcomeDate(a);
            final db = _outcomeDate(b);
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return db.compareTo(da);
          });

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              _refresh();
              await _admissionsFuture;
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.hospital.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SummaryHeroCard(
                          total: total,
                          periodLabel: _period.label,
                        ),
                        const SizedBox(height: 14),
                        _OutcomeStatsRow(
                          improvedCount:
                              counts[AdmissionStatus.discharged] ?? 0,
                          dieCount: counts[AdmissionStatus.deceased] ?? 0,
                          damaCount: counts[AdmissionStatus.leavesAma] ?? 0,
                          improvedPercent: _percent(
                            counts[AdmissionStatus.discharged] ?? 0,
                            total,
                          ),
                          diePercent: _percent(
                            counts[AdmissionStatus.deceased] ?? 0,
                            total,
                          ),
                          damaPercent: _percent(
                            counts[AdmissionStatus.leavesAma] ?? 0,
                            total,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _PeriodChipsRow(
                          selected: _period,
                          onSelected: (next) =>
                              setState(() => _period = next),
                        ),
                        const SizedBox(height: 12),
                        _FilterChipsRow(
                          selected: _filter,
                          onSelected: (next) =>
                              setState(() => _filter = next),
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _searchController,
                          hintText: AppTexts.dischargedSearchHint,
                          textInputAction: TextInputAction.search,
                          onChanged: (_) => setState(() {}),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.textSecondary,
                          ),
                          suffixIcon: hasSearch
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    color: AppColors.textSecondary,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '${filtered.length} patient${filtered.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            if (hasSearch)
                              Text(
                                'Filtered',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.28,
                      child: _DischargedEmptyState(
                        message: hasSearch
                            ? AppTexts.dischargedSearchEmpty
                            : AppTexts.dischargedEmpty,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final admission = filtered[index];
                        final status = AdmissionStatus.fromApiValue(
                          admission.status,
                        );
                        return _DischargedPatientCard(
                          name: _patientName(admission),
                          status: status,
                          outcomeDate: _outcomeDateLabel(admission),
                          bedNumber: admission.bedNumber,
                          admissionId: admission.id,
                          onTap: () async {
                            final refresh = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AdmissionDetailsScreen(
                                  admissionId: admission.id,
                                ),
                              ),
                            );
                            if (refresh == true && mounted) _refresh();
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryHeroCard extends StatelessWidget {
  const _SummaryHeroCard({
    required this.total,
    required this.periodLabel,
  });

  final int total;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F36), Color(0xFF2A3150)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.assignment_turned_in_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$total',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Discharged in $periodLabel',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutcomeStatCard extends StatelessWidget {
  const _OutcomeStatCard({
    required this.label,
    required this.count,
    required this.percent,
    required this.accent,
    required this.icon,
  });

  final String label;
  final int count;
  final String percent;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: AppColors.textPrimary),
                ),
                const Spacer(),
                Text(
                  percent,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutcomeStatsRow extends StatelessWidget {
  const _OutcomeStatsRow({
    required this.improvedCount,
    required this.dieCount,
    required this.damaCount,
    required this.improvedPercent,
    required this.diePercent,
    required this.damaPercent,
  });

  final int improvedCount;
  final int dieCount;
  final int damaCount;
  final String improvedPercent;
  final String diePercent;
  final String damaPercent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _OutcomeStatCard(
          label: AppTexts.dischargedStatsImproved,
          count: improvedCount,
          percent: improvedPercent,
          accent: const Color(0xFFD1E7DD),
          icon: Icons.trending_up_rounded,
        ),
        const SizedBox(width: 8),
        _OutcomeStatCard(
          label: AppTexts.dischargedStatsDie,
          count: dieCount,
          percent: diePercent,
          accent: const Color(0xFFF8D7DA),
          icon: Icons.favorite_border_rounded,
        ),
        const SizedBox(width: 8),
        _OutcomeStatCard(
          label: AppTexts.dischargedStatsDama,
          count: damaCount,
          percent: damaPercent,
          accent: const Color(0xFFD1D2F9),
          icon: Icons.exit_to_app_rounded,
        ),
      ],
    );
  }
}

class _PeriodChipsRow extends StatelessWidget {
  const _PeriodChipsRow({
    required this.selected,
    required this.onSelected,
  });

  final DischargedDatePeriod selected;
  final ValueChanged<DischargedDatePeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Time period',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: DischargedDatePeriod.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final period = DischargedDatePeriod.values[index];
              final isSelected = selected == period;
              return ChoiceChip(
                label: Text(period.label),
                selected: isSelected,
                onSelected: (_) => onSelected(period),
                selectedColor: AppColors.primary.withValues(alpha: 0.14),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
                backgroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({
    required this.selected,
    required this.onSelected,
  });

  final DischargedPatientsFilter selected;
  final ValueChanged<DischargedPatientsFilter> onSelected;

  static const _chipData = <(DischargedPatientsFilter, String, Color, IconData)>[
    (
      DischargedPatientsFilter.all,
      AppTexts.dischargedFilterAll,
      AppColors.surface,
      Icons.grid_view_rounded,
    ),
    (
      DischargedPatientsFilter.improved,
      AppTexts.dischargedStatsImproved,
      Color(0xFFD1E7DD),
      Icons.check_circle_outline,
    ),
    (
      DischargedPatientsFilter.die,
      AppTexts.dischargedStatsDie,
      Color(0xFFF8D7DA),
      Icons.favorite_border,
    ),
    (
      DischargedPatientsFilter.dama,
      AppTexts.dischargedStatsDama,
      Color(0xFFD1D2F9),
      Icons.logout_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Outcome',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _chipData.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final (filter, label, fill, icon) = _chipData[index];
              final isSelected = selected == filter;
              return FilterChip(
                label: Text(label),
                avatar: Icon(
                  icon,
                  size: 15,
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                selected: isSelected,
                onSelected: (_) => onSelected(filter),
                selectedColor: fill,
                checkmarkColor: AppColors.primary,
                showCheckmark: false,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
                backgroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                visualDensity: VisualDensity.compact,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DischargedPatientCard extends StatelessWidget {
  const _DischargedPatientCard({
    required this.name,
    required this.status,
    required this.outcomeDate,
    required this.bedNumber,
    required this.admissionId,
    required this.onTap,
  });

  final String name;
  final AdmissionStatus status;
  final String outcomeDate;
  final String bedNumber;
  final int admissionId;
  final VoidCallback onTap;

  Color get _accent {
    switch (status) {
      case AdmissionStatus.discharged:
        return const Color(0xFF2E7D32);
      case AdmissionStatus.deceased:
        return AppColors.error;
      case AdmissionStatus.leavesAma:
        return const Color(0xFF5C6BC0);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                color: _accent,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: status.dischargedOutcomeBackground,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            status.dischargedScreenLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        _MetaItem(
                          icon: Icons.event_outlined,
                          label: outcomeDate,
                        ),
                        if (bedNumber.isNotEmpty)
                          _MetaItem(
                            icon: Icons.bed_outlined,
                            label: 'Bed $bedNumber',
                          ),
                        _MetaItem(
                          icon: Icons.tag_outlined,
                          label: '#$admissionId',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
                  const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
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

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _DischargedEmptyState extends StatelessWidget {
  const _DischargedEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 40,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DischargedErrorState extends StatelessWidget {
  const _DischargedErrorState({
    required this.message,
    required this.onRetry,
  });

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
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: AppTexts.retry,
              width: 180,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
