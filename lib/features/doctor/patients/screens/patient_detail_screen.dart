import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_spacing.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/core/utils/date_formatters.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/confirm_action_dialog.dart';
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
    final ok = await ConfirmActionDialog.show(
      context,
      title: AppTexts.deletePatientAdmin,
      message: AppTexts.deletePatientConfirmation,
      confirmLabel: AppTexts.deletePatientAdmin,
    );
    if (!ok || !mounted) return;
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
        builder: (_) => DoctorPatientFormScreen(existing: _draftFrom(patient)),
      ),
    );
    if (saved == true && mounted) _reload();
  }

  String _shortDate(String raw) => isoDateOnly(raw);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppTexts.patientDetailsTitle),
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
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      msg,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(label: AppTexts.retry, onPressed: _reload),
                  ],
                ),
              ),
            );
          }
          final patient = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
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
                    padding: const EdgeInsets.all(AppSpacing.md),
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
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                patient.name,
                                style: Theme.of(context).textTheme.titleLarge,
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
                        const SizedBox(height: AppSpacing.sm),
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
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          AppTexts.notes,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          patient.notes.isEmpty
                              ? AppTexts.notAvailable
                              : patient.notes,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${AppTexts.admissionsSection} (${patient.admissions.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (patient.admissions.isEmpty)
                  Text(
                    'No admissions on record.',
                    style: Theme.of(context).textTheme.bodyMedium,
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
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(h, style: Theme.of(context).textTheme.bodySmall),
                                if ((a.dateComes ?? '').isNotEmpty)
                                  Text(
                                    '${AppTexts.admitted}: ${_shortDate(a.dateComes!)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Builder(
      builder: (context) {
        final labelStyle = Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary);
        final valueStyle = Theme.of(context).textTheme.labelLarge;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 110, child: Text(label, style: labelStyle)),
              Expanded(
                child: Text(
                  value.isEmpty ? AppTexts.notAvailable : value,
                  style: valueStyle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
