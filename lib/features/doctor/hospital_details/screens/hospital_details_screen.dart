import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/core/widgets/app_button.dart';

import '../../home/models/doctor_hospital.dart';
import '../../../superAdmin/patients/models/patient_admission_models.dart';
import '../enums/admission_status.dart';
import '../repository/hospital_admissions_repository.dart';
import '../widgets/admission_status_filter_row.dart';
import '../widgets/admission_tile.dart';
import '../widgets/hospital_group_bed_card.dart';
import 'admission_details_screen.dart';
import 'admission_form_screen.dart';
import 'hospital_doctors_screen.dart';

class HospitalDetailsScreen extends StatefulWidget {
  const HospitalDetailsScreen({super.key, required this.hospital});

  final DoctorHospital hospital;

  @override
  State<HospitalDetailsScreen> createState() => _HospitalDetailsScreenState();
}

class _HospitalDetailsScreenState extends State<HospitalDetailsScreen> {
  static const List<AdmissionStatus> _statuses = AdmissionStatus.values;

  AdmissionStatus _statusFilter = AdmissionStatus.admitted;
  late Future<List<PatientAdmissionModel>> _admissionsFuture;
  late Future<List<PatientAdmissionModel>> _bedOccupancyFuture;

  @override
  void initState() {
    super.initState();
    _admissionsFuture = _fetchAdmissions();
    _bedOccupancyFuture = _fetchBedOccupancy();
  }

  Future<List<PatientAdmissionModel>> _fetchAdmissions() {
    return const HospitalAdmissionsRepository().listAdmissions(
      hospitalId: widget.hospital.id,
      status: _statusFilter.apiValue,
    );
  }

  Future<List<PatientAdmissionModel>> _fetchBedOccupancy() {
    return const HospitalAdmissionsRepository().listAdmissions(
      hospitalId: widget.hospital.id,
      status: AdmissionStatus.admitted.apiValue,
    );
  }

  void _setStatus(AdmissionStatus status) {
    if (status == _statusFilter) return;
    setState(() {
      _statusFilter = status;
      _admissionsFuture = _fetchAdmissions();
    });
  }

  void _refreshAdmissionsAndBeds() {
    setState(() {
      _admissionsFuture = _fetchAdmissions();
      _bedOccupancyFuture = _fetchBedOccupancy();
    });
  }

  Future<void> _onPullToRefresh() async {
    setState(() {
      _admissionsFuture = _fetchAdmissions();
      _bedOccupancyFuture = _fetchBedOccupancy();
    });
    try {
      await Future.wait([_admissionsFuture, _bedOccupancyFuture]);
    } catch (_) {}
  }

  Future<void> _openAdmissionForm(
    String bedNumber,
    int? hospitalGroupId,
  ) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdmissionFormScreen(
          hospitalId: widget.hospital.id,
          initialBedNumber: bedNumber,
          hospitalGroupId: hospitalGroupId,
        ),
      ),
    );
    if (created == true && mounted) {
      _refreshAdmissionsAndBeds();
    }
  }

  Future<void> _onBedTap(
    String bedNumber,
    int? hospitalGroupId,
    int? admissionIdIfOccupied,
  ) async {
    if (admissionIdIfOccupied != null) {
      final refresh = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) =>
              AdmissionDetailsScreen(admissionId: admissionIdIfOccupied),
        ),
      );
      if (refresh == true && mounted) {
        _refreshAdmissionsAndBeds();
      }
      return;
    }
    await _openAdmissionForm(bedNumber, hospitalGroupId);
  }

  @override
  Widget build(BuildContext context) {
    final groups = widget.hospital.groups;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          widget.hospital.name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(2),
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _onPullToRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.hospital.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (widget.hospital.location != null &&
                      widget.hospital.location!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.hospital.location!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  AppButton(
                    label: AppTexts.viewHospitalDoctors,
                    borderRadius: 14,
                    height: 44,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => HospitalDoctorsScreen(
                            hospital: widget.hospital,
                          ),
                        ),
                      );
                    },
                    leadingIcon: const Icon(
                      Icons.groups_2_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    AppTexts.hospitalGroupsSummary,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<PatientAdmissionModel>>(
                    future: _bedOccupancyFuture,
                    builder: (context, snap) {
                      final Map<int?, Set<String>> occ = snap.hasData
                          ? _occupiedBedLabelsByGroup(snap.data!)
                          : <int?, Set<String>>{};
                      final Map<String, int> admissionByBedKey =
                          snap.hasData
                              ? _admissionIdByBedKey(snap.data!)
                              : <String, int>{};

                      if (snap.connectionState == ConnectionState.waiting &&
                          !snap.hasData) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }

                      if (groups.isNotEmpty) {
                        return Column(
                          children: groups
                              .map(
                                (g) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: HospitalGroupBedCard(
                                    groupName: g.name,
                                    totalBeds: g.totalBeds,
                                    availableBeds: g.availableBeds,
                                    groupId: g.id,
                                    occupiedBedLabels: occ[g.id] ?? const {},
                                    admissionIdByBedKey: admissionByBedKey,
                                    onBedTap: _onBedTap,
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      }

                      return HospitalGroupBedCard(
                        groupName: AppTexts.hospitalBedsSummary,
                        totalBeds: widget.hospital.totalBeds,
                        availableBeds: widget.hospital.availableBeds,
                        groupId: null,
                        occupiedBedLabels: occ[null] ?? const {},
                        admissionIdByBedKey: admissionByBedKey,
                        onBedTap: _onBedTap,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTexts.admissionsSection,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AdmissionStatusFilterRow(
                    statuses: _statuses,
                    selected: _statusFilter,
                    onSelected: _setStatus,
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<PatientAdmissionModel>>(
                    future: _admissionsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        final message = snapshot.error is NetworkException
                            ? (snapshot.error as NetworkException).message
                            : 'Failed to load admissions.';
                        return Column(
                          children: [
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            AppButton(
                              label: AppTexts.retry,
                              height: 42,
                              onPressed: _refreshAdmissionsAndBeds,
                            ),
                          ],
                        );
                      }

                      final admissions = snapshot.data ?? const [];
                      if (admissions.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No admissions found.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        );
                      }

                      return Column(
                        children: admissions
                            .map(
                              (a) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: AdmissionTile(
                                  admission: a,
                                  formatIsoDateTime: _formatIsoDateTime,
                                  onTap: () async {
                                    final refresh = await Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AdmissionDetailsScreen(
                                                  admissionId: a.id,
                                                ),
                                          ),
                                        );
                                    if (refresh == true) {
                                      _refreshAdmissionsAndBeds();
                                    }
                                  },
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _admissionOccupiesBed(PatientAdmissionModel a) {
  if (a.status.toLowerCase().trim() != 'admitted') return false;
  final leave = a.dateLeave;
  if (leave != null && leave.trim().isNotEmpty) return false;
  return a.bedNumber.trim().isNotEmpty;
}

void _addBedAliases(Set<String> set, String raw) {
  final t = raw.trim();
  if (t.isEmpty) return;
  set.add(t);
  final n = int.tryParse(t);
  if (n != null) set.add('$n');
}

Map<int?, Set<String>> _occupiedBedLabelsByGroup(
  List<PatientAdmissionModel> admissions,
) {
  final m = <int?, Set<String>>{};
  for (final a in admissions) {
    if (!_admissionOccupiesBed(a)) continue;
    _addBedAliases(
      m.putIfAbsent(a.hospitalGroupId, () => <String>{}),
      a.bedNumber,
    );
  }
  return m;
}

Map<String, int> _admissionIdByBedKey(List<PatientAdmissionModel> admissions) {
  final m = <String, int>{};
  for (final a in admissions) {
    if (!_admissionOccupiesBed(a)) continue;
    final gid = a.hospitalGroupId;
    final id = a.id;
    final t = a.bedNumber.trim();
    if (t.isEmpty) continue;
    m[bedOccupancyLookupKey(gid, t)] = id;
    final n = int.tryParse(t);
    if (n != null) m[bedOccupancyLookupKey(gid, '$n')] = id;
  }
  return m;
}

String _formatIsoDateTime(String raw) {
  if (raw.isEmpty) return AppTexts.notAvailable;
  final t = raw.indexOf('T');
  if (t <= 0) return raw;
  final date = raw.substring(0, t);
  final time = raw.length > t + 1
      ? raw.substring(t + 1, raw.length > t + 9 ? t + 9 : raw.length)
      : '';
  return time.isEmpty ? date : '$date $time${AppTexts.utcTimeZoneSuffix}';
}
