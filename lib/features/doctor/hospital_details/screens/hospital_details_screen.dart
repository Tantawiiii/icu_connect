import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/app_text_field.dart';

import '../../home/models/doctor_hospital.dart';
import '../../../superAdmin/patients/models/patient_admission_models.dart';
import '../enums/admission_status.dart';
import '../models/swap_bed_selection.dart';
import '../repository/hospital_admissions_repository.dart';
import '../utils/hospital_bed_occupancy_utils.dart';
import '../widgets/hospital_group_bed_card.dart';
import '../widgets/hospital_group_dropdown.dart';
import '../widgets/hospital_group_stats_row.dart';
import '../widgets/hospital_swap_beds_button.dart';
import '../widgets/hospital_swap_group_quick_picker.dart';
import '../widgets/hospital_swap_mode_banner.dart';
import '../widgets/swap_beds_confirm_sheet.dart';
import 'admission_details_screen.dart';
import 'admission_form_screen.dart';
import 'discharged_patients_screen.dart';
import 'hospital_doctors_screen.dart';
import '../../patients/screens/patient_form_screen.dart';

class HospitalDetailsScreen extends StatefulWidget {
  const HospitalDetailsScreen({super.key, required this.hospital});

  final DoctorHospital hospital;

  @override
  State<HospitalDetailsScreen> createState() => _HospitalDetailsScreenState();
}

class _HospitalDetailsScreenState extends State<HospitalDetailsScreen> {
  final AdmissionStatus _statusFilter = AdmissionStatus.admitted;
  late Future<List<PatientAdmissionModel>> _admissionsFuture;
  late Future<List<PatientAdmissionModel>> _bedOccupancyFuture;
  late final ScrollController _scrollController;
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

  void _openDischargedPatients() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DischargedPatientsScreen(hospital: widget.hospital),
      ),
    );
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
              AppButton(
                label: AppTexts.dischargedPatients,
                borderRadius: 28,
                height: 52,
                onPressed: _openDischargedPatients,
              ),
              const SizedBox(height: 14),
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

                  final occupancy = buildBedOccupancyForGroup(admissions, groupId);
                  final hospitalOccupiedCount = countOccupiedBeds(admissions);
                  final occupiedByGroup = occupiedCountByGroupId(admissions);
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
                        HospitalGroupDropdown(
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
                          HospitalSwapGroupQuickPicker(
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
                      HospitalGroupStatsRow(
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
                        HospitalSwapModeBanner(
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
                          child: HospitalSwapBedsButton(
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
