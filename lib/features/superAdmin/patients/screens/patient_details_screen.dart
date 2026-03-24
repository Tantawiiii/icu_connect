import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
import '../../../../core/network/network_exceptions.dart';
import '../cubit/patient_details_cubit.dart';
import '../cubit/patient_details_state.dart';
import '../models/patient_admission_models.dart';
import '../models/patient_model.dart';
import '../repository/admissions_repository.dart';
import 'admission_form_screen.dart';

class PatientDetailsScreen extends StatelessWidget {
  const PatientDetailsScreen({super.key, required this.patientId});

  final int patientId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PatientDetailsCubit()..fetchPatient(patientId),
      child: _PatientDetailsView(patientId: patientId),
    );
  }
}

class _PatientDetailsView extends StatelessWidget {
  const _PatientDetailsView({required this.patientId});

  final int patientId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PatientDetailsCubit, PatientDetailsState>(
      builder: (context, state) {
        final patient =
            state is PatientDetailsLoaded ? state.patient : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              AppTexts.patientDetailsTitle,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          floatingActionButton: patient != null
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    final saved = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => AdmissionFormScreen(
                          patientId: patient.id,
                          patientName: patient.name,
                        ),
                      ),
                    );
                    if (saved == true && context.mounted) {
                      context
                          .read<PatientDetailsCubit>()
                          .fetchPatient(patientId);
                    }
                  },
                  backgroundColor: AppColors.primary,
                  icon: const Icon(Icons.add),
                  label: Text(AppTexts.addAdmission),
                )
              : null,
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, PatientDetailsState state) {
    if (state is PatientDetailsLoading || state is PatientDetailsInitial) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (state is PatientDetailsFailure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    if (state is PatientDetailsLoaded) {
      return _DetailsContent(patient: state.patient);
    }
    return const SizedBox.shrink();
  }
}

class _DetailsContent extends StatelessWidget {
  const _DetailsContent({required this.patient});

  final PatientModel patient;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary.withAlpha(20),
                    child: Icon(
                      patient.gender.toLowerCase() == 'male'
                          ? Icons.male
                          : patient.gender.toLowerCase() == 'female'
                              ? Icons.female
                              : Icons.person_outline,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${AppTexts.age}: ${patient.age}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        if (patient.bloodGroup.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.bloodtype_outlined,
                                    size: 14,
                                    color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  patient.bloodGroup,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppTexts.identifiersSection,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: AppTexts.nationalId,
                    value: patient.nationalId.isEmpty
                        ? AppTexts.notAvailable
                        : patient.nationalId,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: AppTexts.phone,
                    value: patient.phone.isEmpty
                        ? AppTexts.notAvailable
                        : patient.phone,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: AppTexts.gender,
                    value: patient.gender.isEmpty
                        ? AppTexts.notAvailable
                        : patient.gender[0].toUpperCase() +
                            patient.gender.substring(1),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTexts.notes,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    patient.notes.isEmpty
                        ? AppTexts.notAvailable
                        : patient.notes,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppTexts.recordSection,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: AppTexts.createdLabel,
                    value: _formatIsoDateTime(patient.createdAt),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: AppTexts.updatedLabel,
                    value: _formatIsoDateTime(patient.updatedAt),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),
          const Text(
            AppTexts.admissionsSection,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (patient.admissions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${AppTexts.noAdmissionsYetPrefix}${AppTexts.addAdmission}${AppTexts.noAdmissionsYetSuffix}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...patient.admissions.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _AdmissionCard(patient: patient, admission: a),
              ),
            ),
        ],
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

class _AdmissionCard extends StatelessWidget {
  const _AdmissionCard({required this.patient, required this.admission});

  final PatientModel patient;
  final PatientAdmissionModel admission;

  Future<void> _onDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppTexts.deleteAdmission),
        content: Text(AppTexts.deleteAdmissionConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppTexts.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppTexts.deleteAdmission,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    try {
      await const AdmissionsRepository().deleteAdmission(admission.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTexts.admissionDeleted),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.read<PatientDetailsCubit>().fetchPatient(patient.id);
      }
    } on NetworkException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = admission.hospital;
    final d = admission.doctor;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_hospital_outlined,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppTexts.admissionCardTitle(
                      admission.id,
                      admission.bedNumber.isEmpty
                          ? admission.status
                          : admission.bedNumber,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(28),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    admission.status,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final saved = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => AdmissionFormScreen(
                          patientId: patient.id,
                          patientName: patient.name,
                          admission: admission,
                        ),
                      ),
                    );
                    if (saved == true && context.mounted) {
                      context
                          .read<PatientDetailsCubit>()
                          .fetchPatient(patient.id);
                    }
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(AppTexts.editAdmission),
                ),
                TextButton.icon(
                  onPressed: () => _onDelete(context),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(AppTexts.deleteAdmission),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (h != null) ...[
              const Text(
                AppTexts.patientDetailsHospital,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              _InfoRow(label: AppTexts.name, value: h.name),
              const SizedBox(height: 6),
              _InfoRow(label: AppTexts.location, value: h.location),
              const SizedBox(height: 6),
              _InfoRow(
                label: AppTexts.totalBeds,
                value: '${h.totalBeds}',
              ),
              const SizedBox(height: 6),
              _InfoRow(
                label: AppTexts.availableBeds,
                value: '${h.availableBeds}',
              ),
              const SizedBox(height: 14),
            ],
            if (d != null) ...[
              const Text(
                AppTexts.patientDetailsDoctor,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              _InfoRow(label: AppTexts.name, value: d.name),
              const SizedBox(height: 6),
              _InfoRow(label: AppTexts.emailLabel, value: d.email),
              const SizedBox(height: 6),
              _InfoRow(label: AppTexts.phone, value: d.phone.isEmpty ? AppTexts.notAvailable : d.phone),
              const SizedBox(height: 6),
              _InfoRow(
                label: AppTexts.roleLabel,
                value: d.role.replaceAll('_', ' '),
              ),
              const SizedBox(height: 14),
            ],
            _InfoRow(
              label: AppTexts.admitted,
              value: _formatIsoDateTime(admission.dateComes ?? ''),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: AppTexts.dischargedLabel,
              value: admission.dateLeave != null && admission.dateLeave!.isNotEmpty
                  ? _formatIsoDateTime(admission.dateLeave!)
                  : AppTexts.notAvailable,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: AppTexts.dateOfDeathLabel,
              value: admission.dateOfDeath != null &&
                      admission.dateOfDeath!.isNotEmpty
                  ? _formatIsoDateTime(admission.dateOfDeath!)
                  : AppTexts.notAvailable,
            ),
            const SizedBox(height: 12),
            const Text(
              AppTexts.admissionNotesSection,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              admission.notes.isEmpty ? AppTexts.notAvailable : admission.notes,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
            if (admission.clinicalNotes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                AppTexts.clinicalNotesSection,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ...admission.clinicalNotes.map(
                (n) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.type.replaceAll('_', ' '),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          n.content,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatIsoDateTime(n.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (admission.radiologyImages.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                AppTexts.radiology,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ...admission.radiologyImages.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (r.imagePath.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            r.imagePath,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          r.report.isEmpty ? AppTexts.notAvailable : r.report,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (admission.treatmentPlans.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                AppTexts.treatmentPlansSection,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ...admission.treatmentPlans.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Text(
                      p.planContent,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (admission.vitals.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                AppTexts.vitalsLabel,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ...admission.vitals.map(
                (v) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MeasurementRow(
                    title: v.vitalsTitle?.title ??
                        AppTexts.defaultVitalMeasurementTitle,
                    unit: v.vitalsTitle?.unit ?? '',
                    value: v.value,
                    normalMin: v.vitalsTitle?.normalRangeMin,
                    normalMax: v.vitalsTitle?.normalRangeMax,
                    date: v.date,
                  ),
                ),
              ),
            ],
            if (admission.labs.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                AppTexts.labs,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ...admission.labs.map(
                (lab) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MeasurementRow(
                    title: lab.labsTitle?.title ??
                        AppTexts.defaultLabMeasurementTitle,
                    unit: lab.labsTitle?.unit ?? '',
                    value: lab.value,
                    normalMin: lab.labsTitle?.normalRangeMin,
                    normalMax: lab.labsTitle?.normalRangeMax,
                    date: lab.date,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MeasurementRow extends StatelessWidget {
  const _MeasurementRow({
    required this.title,
    required this.unit,
    required this.value,
    this.normalMin,
    this.normalMax,
    required this.date,
  });

  final String title;
  final String unit;
  final String value;
  final String? normalMin;
  final String? normalMax;
  final String date;

  @override
  Widget build(BuildContext context) {
    final range = (normalMin != null &&
            normalMax != null &&
            normalMin!.isNotEmpty &&
            normalMax!.isNotEmpty)
        ? '$normalMin–$normalMax ${unit.isNotEmpty ? unit : ''}'
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${title.toUpperCase()}${unit.isNotEmpty ? ' ($unit)' : ''}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (range != null) ...[
            const SizedBox(height: 2),
            Text(
              '${AppTexts.normalRangePrefix} $range',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            _formatIsoDateTime(date),
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

