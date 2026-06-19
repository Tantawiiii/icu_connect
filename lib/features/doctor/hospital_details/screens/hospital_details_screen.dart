import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/app_text_field.dart';

import '../../home/models/doctor_hospital.dart';
import '../../../superAdmin/patients/models/patient_admission_models.dart';
import '../enums/admission_status.dart';
import '../models/swap_bed_selection.dart';
import '../repository/hospital_admissions_repository.dart';
import '../widgets/admission_status_filter_row.dart';
import '../widgets/admission_tile.dart';
import '../widgets/hospital_group_bed_card.dart';
import '../widgets/swap_beds_confirm_sheet.dart';
import 'admission_details_screen.dart';
import 'admission_form_screen.dart';
import 'hospital_doctors_screen.dart';
import '../../patients/screens/patient_form_screen.dart';

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
  late final ScrollController _scrollController;
  final GlobalKey _admissionsSectionKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  int? _selectedGroupId;
  bool _swapMode = false;
  SwapBedSelection? _firstSwapBed;
  SwapBedSelection? _secondSwapBed;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController.addListener(() => setState(() {}));
    final groups = widget.hospital.groups;
    if (groups.isNotEmpty) {
      _selectedGroupId = groups.first.id;
    }
    _admissionsFuture = _fetchAdmissions();
    _bedOccupancyFuture = _fetchBedOccupancy();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  HospitalGroup? _resolveSelectedGroup(List<HospitalGroup> groups) {
    if (groups.isEmpty) return null;
    for (final group in groups) {
      if (group.id == _selectedGroupId) return group;
    }
    return groups.first;
  }

  void _ensureSelectedGroup(List<HospitalGroup> groups) {
    if (groups.isEmpty) return;
    final valid = groups.any((group) => group.id == _selectedGroupId);
    if (valid) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _selectedGroupId = groups.first.id);
    });
  }

  List<HospitalGroup> _effectiveGroups(List<PatientAdmissionModel>? admissions) {
    if (widget.hospital.groups.isNotEmpty) return widget.hospital.groups;
    if (admissions == null) return const [];

    final byId = <int, HospitalGroup>{};
    for (final admission in admissions) {
      final group = admission.hospitalGroup;
      if (group == null || byId.containsKey(group.id)) continue;
      byId[group.id] = HospitalGroup(
        id: group.id,
        name: group.name,
        totalBeds: group.totalBeds,
        availableBeds: group.availableBeds,
      );
    }
    return byId.values.toList();
  }

  void _scrollToAdmissions() {
    final context = _admissionsSectionKey.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _showDischargedPatients() {
    _setStatus(AdmissionStatus.discharged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToAdmissions());
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

  void _exitSwapMode() {
    setState(() {
      _swapMode = false;
      _firstSwapBed = null;
      _secondSwapBed = null;
    });
  }

  void _enterSwapMode({SwapBedSelection? preselected}) {
    setState(() {
      _swapMode = true;
      _firstSwapBed = preselected;
      _secondSwapBed = null;
    });
  }

  SwapBedSelection _selectionFromBed(
    String bedNumber,
    int? groupId,
    int admissionId,
    BedOccupancyData occupancy,
    List<HospitalGroup> groups,
  ) {
    final bedKey = bedOccupancyLookupKey(groupId, bedNumber);
    final patientName =
        occupancy.patientNameByBedKey[bedKey]?.trim() ?? '';
    return SwapBedSelection(
      bedLabel: bedNumber,
      admissionId: admissionId,
      patientName: patientName,
      bedKey: bedKey,
      groupId: groupId,
      groupName: _groupNameForId(groups, groupId),
    );
  }

  String _groupNameForId(List<HospitalGroup> groups, int? groupId) {
    if (groupId == null) return '';
    for (final group in groups) {
      if (group.id == groupId) return group.name;
    }
    return '';
  }

  Future<void> _maybeConfirmSwap() async {
    final first = _firstSwapBed;
    final second = _secondSwapBed;
    if (first == null || second == null) return;

    final swapped = await showSwapBedsConfirmSheet(
      context: context,
      first: first,
      second: second,
    );
    if (!mounted) return;

    if (swapped) {
      _exitSwapMode();
      _refreshAdmissionsAndBeds();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppTexts.swapBedsSuccess)),
      );
    }
  }

  void _handleSwapBedTap(
    String bedNumber,
    int? groupId,
    int admissionId,
    BedOccupancyData occupancy,
    List<HospitalGroup> groups,
  ) {
    final selection = _selectionFromBed(
      bedNumber,
      groupId,
      admissionId,
      occupancy,
      groups,
    );

    if (_firstSwapBed?.bedKey == selection.bedKey) {
      setState(() {
        _firstSwapBed = null;
        _secondSwapBed = null;
      });
      return;
    }
    if (_secondSwapBed?.bedKey == selection.bedKey) {
      setState(() => _secondSwapBed = null);
      return;
    }

    if (_firstSwapBed == null) {
      setState(() => _firstSwapBed = selection);
      return;
    }

    setState(() => _secondSwapBed = selection);
    _maybeConfirmSwap();
  }

  void _onOccupiedBedLongPress(
    String bedNumber,
    int? groupId,
    int admissionId,
    String patientName,
    List<HospitalGroup> groups,
  ) {
    if (_swapMode) return;
    _enterSwapMode(
      preselected: SwapBedSelection(
        bedLabel: bedNumber,
        admissionId: admissionId,
        patientName: patientName,
        bedKey: bedOccupancyLookupKey(groupId, bedNumber),
        groupId: groupId,
        groupName: _groupNameForId(groups, groupId),
      ),
    );
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

  Future<void> _openEmptyBedFlow(
    String bedNumber,
    int? hospitalGroupId,
  ) async {
    final patientId = await Navigator.of(context).push<int?>(
      MaterialPageRoute(builder: (_) => const PatientFormScreen()),
    );
    if (patientId == null || !mounted) return;

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdmissionFormScreen(
          hospitalId: widget.hospital.id,
          initialBedNumber: bedNumber,
          hospitalGroupId: hospitalGroupId,
          initialPatientId: patientId,
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
    BedOccupancyData occupancy,
    List<HospitalGroup> groups,
  ) async {
    if (_swapMode) {
      if (admissionIdIfOccupied == null) return;
      _handleSwapBedTap(
        bedNumber,
        hospitalGroupId,
        admissionIdIfOccupied,
        occupancy,
        groups,
      );
      return;
    }

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
    await _openEmptyBedFlow(bedNumber, hospitalGroupId);
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
          widget.hospital.name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _onPullToRefresh,
          child: ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 8),
              FutureBuilder<List<PatientAdmissionModel>>(
                future: _bedOccupancyFuture,
                builder: (context, snap) {
                  final admissions = snap.data ?? const [];
                  final groups = _effectiveGroups(snap.hasData ? admissions : null);
                  _ensureSelectedGroup(groups);
                  final selectedGroup = _resolveSelectedGroup(groups);
                  final groupId = selectedGroup?.id;

                  if (snap.connectionState == ConnectionState.waiting &&
                      !snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }

                  final occupancy = _buildBedOccupancyForGroup(admissions, groupId);
                  final hospitalOccupiedCount = _countOccupiedBeds(admissions);
                  final occupiedByGroup = _occupiedCountByGroupId(admissions);
                  final baseTotalBeds =
                      selectedGroup?.totalBeds ?? widget.hospital.totalBeds;
                  final maxOccupiedBed = occupancy.occupiedBedLabels
                      .map(int.tryParse)
                      .whereType<int>()
                      .fold(0, (max, bed) => bed > max ? bed : max);
                  final totalBeds = math.max(baseTotalBeds, maxOccupiedBed);
                  final availableBeds = selectedGroup?.availableBeds ??
                      math.max(0, totalBeds - occupancy.occupiedBedLabels.length);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (groups.isNotEmpty) ...[
                        _GroupDropdown(
                          groups: groups,
                          selectedGroupId: _selectedGroupId ?? selectedGroup?.id,
                          onChanged: (nextGroupId) {
                            setState(() => _selectedGroupId = nextGroupId);
                          },
                        ),
                        if (_swapMode &&
                            groups.length > 1 &&
                            _firstSwapBed != null &&
                            _secondSwapBed == null) ...[
                          const SizedBox(height: 10),
                          _SwapGroupQuickPicker(
                            groups: groups,
                            selectedGroupId: _selectedGroupId ?? selectedGroup?.id,
                            firstGroupId: _firstSwapBed!.groupId,
                            occupiedByGroupId: occupiedByGroup,
                            onGroupSelected: (nextGroupId) {
                              setState(() => _selectedGroupId = nextGroupId);
                            },
                          ),
                        ],
                        const SizedBox(height: 14),
                      ],
                      _GroupStatsRow(
                        totalBeds: totalBeds,
                        availableBeds: availableBeds,
                        onDoctorsTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => HospitalDoctorsScreen(
                                hospital: widget.hospital,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _searchController,
                        hintText: AppTexts.searchBedsHint,
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
                      const SizedBox(height: 14),
                      if (_swapMode)
                        _SwapModeBanner(
                          first: _firstSwapBed,
                          second: _secondSwapBed,
                          showCrossGroupHint:
                              groups.length > 1 &&
                              _firstSwapBed != null &&
                              _secondSwapBed == null,
                          onCancel: _exitSwapMode,
                          onReview: _firstSwapBed != null && _secondSwapBed != null
                              ? _maybeConfirmSwap
                              : null,
                        ),
                      if (_swapMode) const SizedBox(height: 10),
                      if (!_swapMode && hospitalOccupiedCount >= 2)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SwapBedsButton(
                            onPressed: () => _enterSwapMode(),
                          ),
                        ),
                      HospitalGroupBedCard(
                        totalBeds: totalBeds,
                        groupId: groupId,
                        searchQuery: _searchController.text,
                        occupiedBedLabels: occupancy.occupiedBedLabels,
                        admissionIdByBedKey: occupancy.admissionIdByBedKey,
                        patientNameByBedKey: occupancy.patientNameByBedKey,
                        swapMode: _swapMode,
                        firstSwapBedKey: _firstSwapBed?.bedKey,
                        secondSwapBedKey: _secondSwapBed?.bedKey,
                        onBedTap: (bed, gid, admissionId) => _onBedTap(
                          bed,
                          gid,
                          admissionId,
                          occupancy,
                          groups,
                        ),
                        onOccupiedBedLongPress: (bed, gid, admissionId, name) {
                          _onOccupiedBedLongPress(
                            bed,
                            gid,
                            admissionId,
                            name,
                            groups,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              AppButton(
                label: AppTexts.dischargedPatients,
                borderRadius: 28,
                height: 52,
                onPressed: _showDischargedPatients,
              ),
              const SizedBox(height: 24),
              Padding(
                key: _admissionsSectionKey,
                padding: const EdgeInsets.only(bottom: 16),
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
                        final filteredAdmissions = _filterAdmissions(
                          admissions,
                          _searchController.text,
                        );
                        if (admissions.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No admissions found.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          );
                        }
                        if (filteredAdmissions.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              AppTexts.bedsSearchEmpty,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.9,
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: filteredAdmissions
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

class _GroupDropdown extends StatelessWidget {
  const _GroupDropdown({
    required this.groups,
    required this.selectedGroupId,
    required this.onChanged,
  });

  final List<HospitalGroup> groups;
  final int? selectedGroupId;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.textPrimary, width: 1.4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: selectedGroupId,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textPrimary,
          ),
          hint: Text(AppTexts.selectHospitalGroup),
          items: groups
              .map(
                (group) => DropdownMenuItem<int>(
                  value: group.id,
                  child: Text(
                    group.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

class _GroupStatsRow extends StatelessWidget {
  const _GroupStatsRow({
    required this.totalBeds,
    required this.availableBeds,
    required this.onDoctorsTap,
  });

  final int totalBeds;
  final int availableBeds;
  final VoidCallback onDoctorsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
          label: '${AppTexts.totalBedsShort} : $totalBeds',
        ),
        const SizedBox(width: 8),
        _StatChip(
          label: '${AppTexts.availableBedsShort} : $availableBeds',
        ),
        const Spacer(),
        Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(999),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onDoctorsTap,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Text(
                AppTexts.viewHospitalDoctors,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.textPrimary, width: 1.2),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

bool _admissionOccupiesBed(PatientAdmissionModel a) {
  if (a.status.toLowerCase().trim() != 'admitted') return false;
  final leave = a.dateLeave;
  if (leave != null && leave.trim().isNotEmpty) return false;
  return normalizeBedNumber(a.bedNumber).isNotEmpty;
}

List<PatientAdmissionModel> _filterAdmissions(
  List<PatientAdmissionModel> admissions,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return admissions;

  return admissions.where((admission) {
    if (normalizeBedNumber(admission.bedNumber).contains(q)) return true;
    if (admission.bedNumber.toLowerCase().contains(q)) return true;
    final name = admission.patient?.name.toLowerCase() ?? '';
    return name.contains(q);
  }).toList();
}

BedOccupancyData _buildBedOccupancyForGroup(
  List<PatientAdmissionModel> admissions,
  int? groupId,
) {
  final occupied = <String>{};
  final admissionIds = <String, int>{};
  final patientNames = <String, String>{};

  for (final admission in admissions) {
    if (!_admissionOccupiesBed(admission)) continue;
    if (groupId != null && admission.hospitalGroupId != groupId) continue;

    final bed = normalizeBedNumber(admission.bedNumber);
    if (bed.isEmpty) continue;

    occupied.add(bed);
    final key = bedOccupancyLookupKey(groupId, bed);
    admissionIds[key] = admission.id;

    final name = admission.patient?.name.trim();
    if (name != null && name.isNotEmpty) {
      patientNames[key] = name;
    }
  }

  return BedOccupancyData(
    occupiedBedLabels: occupied,
    admissionIdByBedKey: admissionIds,
    patientNameByBedKey: patientNames,
  );
}

int _countOccupiedBeds(List<PatientAdmissionModel> admissions) {
  var count = 0;
  for (final admission in admissions) {
    if (!_admissionOccupiesBed(admission)) continue;
    if (normalizeBedNumber(admission.bedNumber).isEmpty) continue;
    count++;
  }
  return count;
}

Map<int, int> _occupiedCountByGroupId(List<PatientAdmissionModel> admissions) {
  final counts = <int, int>{};
  for (final admission in admissions) {
    if (!_admissionOccupiesBed(admission)) continue;
    if (normalizeBedNumber(admission.bedNumber).isEmpty) continue;
    final gid = admission.hospitalGroupId;
    if (gid == null) continue;
    counts[gid] = (counts[gid] ?? 0) + 1;
  }
  return counts;
}

String _swapBedLocationLabel(SwapBedSelection selection) {
  final bed = '${AppTexts.bedLabel} ${selection.bedLabel}';
  if (selection.groupName.isEmpty) return bed;
  return '${selection.groupName} · $bed';
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

class _SwapBedsButton extends StatelessWidget {
  const _SwapBedsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.55),
              width: 1.4,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                size: 20,
                color: AppColors.primary.withValues(alpha: 0.95),
              ),
              const SizedBox(width: 8),
              Text(
                AppTexts.swapBeds,
                style: TextStyle(
                  color: AppColors.primary.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwapModeBanner extends StatelessWidget {
  const _SwapModeBanner({
    required this.first,
    required this.second,
    required this.onCancel,
    this.onReview,
    this.showCrossGroupHint = false,
  });

  final SwapBedSelection? first;
  final SwapBedSelection? second;
  final VoidCallback onCancel;
  final VoidCallback? onReview;
  final bool showCrossGroupHint;

  @override
  Widget build(BuildContext context) {
    final stepText = first == null
        ? AppTexts.swapBedsSelectFirst
        : second == null
            ? AppTexts.swapBedsSelectSecond
            : AppTexts.swapBedsConfirmTitle;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  stepText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
              TextButton(
                onPressed: onCancel,
                child: Text(
                  AppTexts.cancel,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (showCrossGroupHint) ...[
            const SizedBox(height: 8),
            Text(
              AppTexts.swapBedsSwitchGroupHint,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary.withValues(alpha: 0.95),
                height: 1.3,
              ),
            ),
          ],
          if (first != null) ...[
            const SizedBox(height: 10),
            if (second != null &&
                first!.groupId != null &&
                second!.groupId != null &&
                first!.groupId != second!.groupId)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  AppTexts.swapBedsCrossGroupNote,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary.withValues(alpha: 0.9),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: _MiniSwapChip(
                    label: _swapBedLocationLabel(first!),
                    subtitle: first!.patientName,
                    color: AppColors.primary,
                  ),
                ),
                if (second != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                  Expanded(
                    child: _MiniSwapChip(
                      label: _swapBedLocationLabel(second!),
                      subtitle: second!.patientName,
                      color: const Color(0xFFFF9800),
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (onReview != null) ...[
            const SizedBox(height: 10),
            AppButton(
              label: AppTexts.confirmSwap,
              height: 44,
              borderRadius: 22,
              onPressed: onReview,
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniSwapChip extends StatelessWidget {
  const _MiniSwapChip({
    required this.label,
    required this.subtitle,
    required this.color,
  });

  final String label;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SwapGroupQuickPicker extends StatelessWidget {
  const _SwapGroupQuickPicker({
    required this.groups,
    required this.selectedGroupId,
    required this.firstGroupId,
    required this.occupiedByGroupId,
    required this.onGroupSelected,
  });

  final List<HospitalGroup> groups;
  final int? selectedGroupId;
  final int? firstGroupId;
  final Map<int, int> occupiedByGroupId;
  final ValueChanged<int> onGroupSelected;

  @override
  Widget build(BuildContext context) {
    final visibleGroups = groups
        .where((g) => (occupiedByGroupId[g.id] ?? 0) > 0)
        .toList();
    if (visibleGroups.length < 2) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibleGroups.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final group = visibleGroups[index];
          final isSelected = group.id == selectedGroupId;
          final isFirstGroup = group.id == firstGroupId;
          final occupied = occupiedByGroupId[group.id] ?? 0;

          return Material(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.14)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onGroupSelected(group.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : isFirstGroup
                            ? AppColors.primary.withValues(alpha: 0.45)
                            : AppColors.border,
                    width: isSelected ? 1.6 : 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isFirstGroup) ...[
                      Icon(
                        Icons.looks_one_rounded,
                        size: 16,
                        color: AppColors.primary.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      group.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$occupied',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
