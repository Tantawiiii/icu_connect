import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/features/doctor/hospital_details/repository/hospital_admissions_repository.dart';
import 'package:icu_connect/features/doctor/hospital_details/screens/admission_details_screen.dart';
import 'package:icu_connect/features/doctor/patients/screens/patient_form_screen.dart';
import 'package:icu_connect/features/superAdmin/patients/models/patient_admission_models.dart';
import 'package:icu_connect/features/superAdmin/patients/models/patient_model.dart';

class PatientDetailScreen extends StatefulWidget {
  const PatientDetailScreen({super.key, required this.patientId});

  final int patientId;

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final _repository = const HospitalAdmissionsRepository();
  late Future<PatientModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.getPatient(widget.patientId);
  }

  void _reload() {
    setState(() {
      _future = _repository.getPatient(widget.patientId);
    });
  }

  AdmissionPatientModel _draftFrom(PatientModel p) {
    return AdmissionPatientModel(
      id: p.id,
      name: p.name,
      nationalId: p.nationalId,
      age: p.age,
      gender: p.gender,
      phone: p.phone,
      bloodGroup: p.bloodGroup,
      notes: p.notes,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
      deletedAt: p.deletedAt,
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppTexts.deletePatientAdmin),
        content: Text(AppTexts.deletePatientConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppTexts.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppTexts.deletePatientAdmin,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _repository.deletePatient(widget.patientId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on NetworkException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _openEdit(PatientModel patient) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PatientFormScreen(existing: _draftFrom(patient)),
      ),
    );
    if (saved == true && mounted) _reload();
  }

  String _shortDate(String raw) {
    if (raw.isEmpty) return AppTexts.notAvailable;
    final t = raw.indexOf('T');
    return t > 0 ? raw.substring(0, t) : raw;
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
          AppTexts.patientDetailsTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          FutureBuilder<PatientModel>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => _openEdit(snapshot.data!),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                    onPressed: _confirmDelete,
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<PatientModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            final msg = snapshot.error is NetworkException
                ? (snapshot.error as NetworkException).message
                : 'Failed to load patient.';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      msg,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    AppButton(label: AppTexts.retry, onPressed: _reload),
                  ],
                ),
              ),
            );
          }
          final patient = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.2,
                              ),
                              child: Icon(
                                patient.gender.toLowerCase() == 'male'
                                    ? Icons.male
                                    : patient.gender.toLowerCase() == 'female'
                                    ? Icons.female
                                    : Icons.person_outline,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                patient.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (patient.bloodGroup.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  patient.bloodGroup,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _detailRow(AppTexts.nationalId, patient.nationalId),
                        _detailRow(AppTexts.age, '${patient.age}'),
                        _detailRow(
                          AppTexts.gender,
                          patient.gender.isEmpty
                              ? AppTexts.notAvailable
                              : patient.gender,
                        ),
                        _detailRow(AppTexts.phone, patient.phone),
                        _detailRow(
                          AppTexts.createdLabel,
                          _shortDate(patient.createdAt),
                        ),
                        _detailRow(
                          AppTexts.updatedLabel,
                          _shortDate(patient.updatedAt),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppTexts.notes,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          patient.notes.isEmpty
                              ? AppTexts.notAvailable
                              : patient.notes,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${AppTexts.admissionsSection} (${patient.admissions.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                if (patient.admissions.isEmpty)
                  const Text(
                    'No admissions on record.',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                else
                  ...patient.admissions.map((a) {
                    final h = a.hospital?.name ?? AppTexts.notAvailable;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    AdmissionDetailsScreen(admissionId: a.id),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Bed ${a.bedNumber} · ${a.status}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  h,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                if ((a.dateComes ?? '').isNotEmpty)
                                  Text(
                                    '${AppTexts.admitted}: ${_shortDate(a.dateComes!)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? AppTexts.notAvailable : value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
