import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_texts.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/widgets/confirm_action_dialog.dart';
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
        final patient = state is PatientDetailsLoaded ? state.patient : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: const Text(AppTexts.patientDetailsTitle),
            titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontSize: 18,
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
                      context.read<PatientDetailsCubit>().fetchPatient(
                        patientId,
                      );
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
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: AppSpacing.md),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${AppTexts.age}: ${patient.age}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (patient.bloodGroup.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.bloodtype_outlined,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  patient.bloodGroup,
                                  style: Theme.of(context).textTheme.bodySmall,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTexts.identifiersSection,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTexts.notes,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    patient.notes.isEmpty
                        ? AppTexts.notAvailable
                        : patient.notes,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTexts.recordSection,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary),
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
          Text(
            AppTexts.admissionsSection,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          if (patient.admissions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                '${AppTexts.noAdmissionsYetPrefix}${AppTexts.addAdmission}${AppTexts.noAdmissionsYetSuffix}',
                style: Theme.of(context).textTheme.bodySmall,
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

String _formatIsoDateTime(String raw) =>
    isoDateTime(raw, suffix: AppTexts.utcTimeZoneSuffix);

class _AdmissionCard extends StatelessWidget {
  const _AdmissionCard({required this.patient, required this.admission});

  final PatientModel patient;
  final PatientAdmissionModel admission;

  Future<void> _onDelete(BuildContext context) async {
    final confirm = await ConfirmActionDialog.show(
      context,
      title: AppTexts.deleteAdmission,
      message: AppTexts.deleteAdmissionConfirmation,
      confirmLabel: AppTexts.deleteAdmission,
    );
    if (!confirm || !context.mounted) return;

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
                const Icon(
                  Icons.local_hospital_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppTexts.admissionCardTitle(
                      admission.id,
                      admission.bedNumber.isEmpty
                          ? admission.status
                          : admission.bedNumber,
                    ),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(28),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    admission.status,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
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
                      context.read<PatientDetailsCubit>().fetchPatient(
                        patient.id,
                      );
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
              Text(
                AppTexts.patientDetailsHospital,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 6),
              _InfoRow(label: AppTexts.name, value: h.name),
              const SizedBox(height: 6),
              _InfoRow(label: AppTexts.location, value: h.location),
              const SizedBox(height: 6),
              _InfoRow(label: AppTexts.totalBeds, value: '${h.totalBeds}'),
              const SizedBox(height: 6),
              _InfoRow(
                label: AppTexts.availableBeds,
                value: '${h.availableBeds}',
              ),
              const SizedBox(height: 14),
            ],
            if (d != null) ...[
              Text(
                AppTexts.patientDetailsDoctor,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 6),
              _InfoRow(label: AppTexts.name, value: d.name),
              const SizedBox(height: 6),
              _InfoRow(label: AppTexts.emailLabel, value: d.email),
              const SizedBox(height: 6),
              _InfoRow(
                label: AppTexts.phone,
                value: d.phone.isEmpty ? AppTexts.notAvailable : d.phone,
              ),
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
              value:
                  admission.dateLeave != null && admission.dateLeave!.isNotEmpty
                  ? _formatIsoDateTime(admission.dateLeave!)
                  : AppTexts.notAvailable,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: AppTexts.dateOfDeathLabel,
              value:
                  admission.dateOfDeath != null &&
                      admission.dateOfDeath!.isNotEmpty
                  ? _formatIsoDateTime(admission.dateOfDeath!)
                  : AppTexts.notAvailable,
            ),
            const SizedBox(height: 12),
            Text(
              AppTexts.admissionNotesSection,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            Text(
              admission.notes.isEmpty ? AppTexts.notAvailable : admission.notes,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
            ),
            if (admission.clinicalNotes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                AppTexts.clinicalNotesSection,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
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
                          style: Theme.of(
                            context,
                          ).textTheme.labelMedium?.copyWith(color: AppColors.primary),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          n.content,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _formatIsoDateTime(n.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (admission.radiologyImages.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppTexts.radiology,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
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
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        if (r.imagePath.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            r.imagePath,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          r.report.isEmpty ? AppTexts.notAvailable : r.report,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (admission.treatmentPlans.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppTexts.treatmentPlansSection,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
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
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ),
              ),
            ],
            if (admission.vitals.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppTexts.vitalsLabel,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              ...admission.vitals.map(
                (v) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MeasurementRow(
                    title:
                        v.vitalsTitle?.title ??
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
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppTexts.labs,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              ...admission.labs.map(
                (lab) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MeasurementRow(
                    title:
                        lab.labsTitle?.title ??
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
    final range =
        (normalMin != null &&
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
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (range != null) ...[
            const SizedBox(height: 2),
            Text(
              '${AppTexts.normalRangePrefix} $range',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            _formatIsoDateTime(date),
            style: Theme.of(context).textTheme.bodySmall,
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
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
