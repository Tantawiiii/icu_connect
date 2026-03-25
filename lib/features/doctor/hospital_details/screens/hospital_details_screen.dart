import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';

import '../../home/models/doctor_hospital.dart';
import '../../../superAdmin/patients/models/patient_admission_models.dart';
import '../enums/admission_status.dart';
import '../repository/hospital_admissions_repository.dart';
import '../widgets/admission_status_filter_row.dart';
import '../widgets/admission_tile.dart';
import '../widgets/stat_pill.dart';
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

  bool get _isAdminInHospital =>
      (widget.hospital.userStatus.roleInHospital ?? '').toLowerCase().trim() ==
      'admin';

  @override
  void initState() {
    super.initState();
    _admissionsFuture = _fetchAdmissions();
  }

  Future<List<PatientAdmissionModel>> _fetchAdmissions() {
    return const HospitalAdmissionsRepository().listAdmissions(
      hospitalId: widget.hospital.id,
      status: _statusFilter.apiValue,
    );
  }

  void _setStatus(AdmissionStatus status) {
    if (status == _statusFilter) return;
    setState(() {
      _statusFilter = status;
      _admissionsFuture = _fetchAdmissions();
    });
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.hospital.userStatus.status ?? AppTexts.notAvailable;
    final roleInHospital =
        widget.hospital.userStatus.roleInHospital ?? AppTexts.notAvailable;

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ListView(
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          StatPill(
                            label: AppTexts.totalBeds,
                            value: '${widget.hospital.totalBeds}',
                          ),
                          const SizedBox(width: 10),
                          StatPill(
                            label: AppTexts.availableBeds,
                            value: '${widget.hospital.availableBeds}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),


              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTexts.status,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _infoRow(AppTexts.roleInHospital, roleInHospital),
                      _infoRow(AppTexts.status, status),
                      _infoRow(
                        'Assigned',
                        widget.hospital.userStatus.isAssigned ? 'Yes' : 'No',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_isAdminInHospital) ...[
                const SizedBox(height: 12),
                AppButton(
                  label: AppTexts.viewHospitalDoctors,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            HospitalDoctorsScreen(hospital: widget.hospital),
                      ),
                    );
                  },
                  leadingIcon: const Icon(
                    Icons.groups_2_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ],
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
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
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
                                onPressed: () {
                                  setState(() {
                                    _admissionsFuture = _fetchAdmissions();
                                  });
                                },
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
                                      final refresh = await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => AdmissionDetailsScreen(
                                            admissionId: a.id,
                                          ),
                                        ),
                                      );
                                      if (refresh == true) {
                                        setState(() {
                                          _admissionsFuture = _fetchAdmissions();
                                        });
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final created = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdmissionFormScreen(hospitalId: widget.hospital.id),
            ),
          );
          if (created == true) {
            setState(() {
              _admissionsFuture = _fetchAdmissions();
            });
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
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
