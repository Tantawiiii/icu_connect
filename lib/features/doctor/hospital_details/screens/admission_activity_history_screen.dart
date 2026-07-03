import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';

import '../enums/admission_activity_subject_type.dart';
import '../models/admission_activity.dart';
import '../repository/hospital_admissions_repository.dart';
import '../widgets/admission_details_activity_section.dart';

class AdmissionActivityHistoryScreen extends StatefulWidget {
  const AdmissionActivityHistoryScreen({
    super.key,
    required this.admissionId,
  });

  final int admissionId;

  @override
  State<AdmissionActivityHistoryScreen> createState() =>
      _AdmissionActivityHistoryScreenState();
}

class _AdmissionActivityHistoryScreenState
    extends State<AdmissionActivityHistoryScreen> {
  final _repo = const HospitalAdmissionsRepository();
  late Future<List<AdmissionActivity>> _activityFuture;
  AdmissionActivitySubjectType? _activityFilter;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  void _loadActivity() {
    setState(() {
      _activityFuture = _repo.fetchAdmissionActivity(
        widget.admissionId,
        subjectType: _activityFilter,
      );
    });
  }

  void _onFilterChanged(AdmissionActivitySubjectType? filter) {
    if (_activityFilter == filter) return;
    setState(() => _activityFilter = filter);
    _loadActivity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          AppTexts.activityHistorySection,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => _loadActivity(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: AdmissionDetailsActivitySection(
              activitiesFuture: _activityFuture,
              selectedFilter: _activityFilter,
              onFilterChanged: _onFilterChanged,
              onRetry: _loadActivity,
              showSectionTitle: false,
            ),
          ),
        ),
      ),
    );
  }
}
