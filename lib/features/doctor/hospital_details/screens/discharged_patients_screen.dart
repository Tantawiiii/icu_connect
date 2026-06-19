import 'package:bounce/bounce.dart';
import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/core/widgets/app_button.dart';

import '../../../superAdmin/patients/models/patient_admission_models.dart';
import '../../home/models/doctor_hospital.dart';
import '../enums/admission_status.dart';
import '../repository/hospital_admissions_repository.dart';
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
  DischargedPatientsFilter _filter = DischargedPatientsFilter.all;
  DischargedDatePeriod _period = DischargedDatePeriod.lastMonth;

  @override
  void initState() {
    super.initState();
    _admissionsFuture = _loadAdmissions();
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
    if (status == null) return inPeriod;
    return inPeriod
        .where(
          (a) => AdmissionStatus.fromApiValue(a.status) == status,
        )
        .toList();
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: AppTexts.retry,
                      width: 180,
                      onPressed: _refresh,
                    ),
                  ],
                ),
              ),
            );
          }

          final all = snapshot.data ?? const [];
          final inPeriod = _inPeriod(all);
          final filtered = _applyFilters(all);
          final counts = _countsByOutcome(inPeriod);
          final total = inPeriod.length;

          filtered.sort((a, b) {
            final da = _outcomeDate(a);
            final db = _outcomeDate(b);
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return db.compareTo(da);
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: _FilterChipsRow(
                  selected: _filter,
                  onSelected: (next) => setState(() => _filter = next),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _StatsColumn(
                        improved: _percent(
                          counts[AdmissionStatus.discharged] ?? 0,
                          total,
                        ),
                        die: _percent(
                          counts[AdmissionStatus.deceased] ?? 0,
                          total,
                        ),
                        dama: _percent(
                          counts[AdmissionStatus.leavesAma] ?? 0,
                          total,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _PeriodDropdown(
                      value: _period,
                      onChanged: (next) {
                        if (next == null) return;
                        setState(() => _period = next);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              AppTexts.dischargedEmpty,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.95,
                                ),
                              ),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () async {
                            _refresh();
                            await _admissionsFuture;
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final admission = filtered[index];
                              final status =
                                  AdmissionStatus.fromApiValue(admission.status);
                              return _DischargedPatientCard(
                                name: _patientName(admission),
                                backgroundColor: status.dischargedOutcomeBackground,
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
                ),
              ),
            ],
          );
        },
      ),
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

  static const _chipData = <(DischargedPatientsFilter, String, Color)>[
    (DischargedPatientsFilter.all, AppTexts.dischargedFilterAll, Colors.white),
    (
      DischargedPatientsFilter.improved,
      AppTexts.dischargedStatsImproved,
      Color(0xFFD1E7DD),
    ),
    (
      DischargedPatientsFilter.die,
      AppTexts.dischargedStatsDie,
      Color(0xFFF8D7DA),
    ),
    (
      DischargedPatientsFilter.dama,
      AppTexts.dischargedStatsDama,
      Color(0xFFD1D2F9),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _chipData.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final (filter, label, fill) = _chipData[index];
          final isSelected = selected == filter;
          return Material(
            color: isSelected ? fill : Colors.white,
            borderRadius: BorderRadius.circular(999),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onSelected(filter),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.textPrimary,
                    width: 1.3,
                  ),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatsColumn extends StatelessWidget {
  const _StatsColumn({
    required this.improved,
    required this.die,
    required this.dama,
  });

  final String improved;
  final String die;
  final String dama;

  @override
  Widget build(BuildContext context) {
    Text statLine(String label, String value) => Text(
          '$label : $value',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.45,
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        statLine(AppTexts.dischargedStatsImproved, improved),
        statLine(AppTexts.dischargedStatsDie, die),
        statLine(AppTexts.dischargedStatsDama, dama),
      ],
    );
  }
}

class _PeriodDropdown extends StatelessWidget {
  const _PeriodDropdown({
    required this.value,
    required this.onChanged,
  });

  final DischargedDatePeriod value;
  final ValueChanged<DischargedDatePeriod?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DischargedDatePeriod>(
          value: value,
          dropdownColor: AppColors.primary,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white,
            size: 20,
          ),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          items: DischargedDatePeriod.values
              .map(
                (period) => DropdownMenuItem(
                  value: period,
                  child: Text(period.label),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DischargedPatientCard extends StatelessWidget {
  const _DischargedPatientCard({
    required this.name,
    required this.backgroundColor,
    required this.onTap,
  });

  final String name;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Bounce(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.12)),
        ),
        child: Text(
          name,
          textAlign: TextAlign.right,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}
