import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_texts.dart';
import '../../../../core/widgets/confirm_action_dialog.dart';
import '../../../../core/widgets/list_error_view.dart';
import '../../../../core/widgets/status_badge.dart';
import '../cubit/patients_cubit.dart';
import '../cubit/patients_state.dart';
import '../models/patient_model.dart';
import 'patient_form_screen.dart';
import 'patient_details_screen.dart';

class PatientsListScreen extends StatelessWidget {
  const PatientsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PatientsCubit()..fetchPatients(),
      child: const _PatientsListView(),
    );
  }
}

class _PatientsListView extends StatelessWidget {
  const _PatientsListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(AppTexts.patientsLabel),
        titleTextStyle: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 18),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
            onPressed: () => context.read<PatientsCubit>().fetchPatients(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text(AppTexts.addPatientAdmin),
        onPressed: () => _openForm(context, patient: null),
      ),
      body: BlocConsumer<PatientsCubit, PatientsState>(
        listener: (context, state) {
          if (state is PatientsActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state is PatientsActionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PatientsLoading || state is PatientsInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state is PatientsFailure) {
            return ListErrorView(
              message: state.message,
              onRetry: () => context.read<PatientsCubit>().fetchPatients(),
            );
          }
          if (state is PatientsActionLoading) {
            return Stack(
              children: [
                _PatientsList(patients: state.patients),
                const ColoredBox(
                  color: Color(0x55000000),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ],
            );
          }
          if (state is PatientsLoaded) {
            return _PatientsList(patients: state.patients);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _openForm(BuildContext context, {required PatientModel? patient}) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => AdminPatientFormScreen(patient: patient),
          ),
        )
        .then((_) {
          if (context.mounted) context.read<PatientsCubit>().fetchPatients();
        });
  }
}

// ── List ─────────────────────────────────────────────────────────────────────

class _PatientsList extends StatelessWidget {
  const _PatientsList({required this.patients});

  final List<PatientModel> patients;

  @override
  Widget build(BuildContext context) {
    if (patients.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.personal_injury_outlined,
              size: 56,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 12),
            Text('No patients found', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<PatientsCubit>().fetchPatients(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 12, AppSpacing.md, 100),
        itemCount: patients.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${patients.length} '
                '${patients.length == 1 ? 'patient' : 'patients'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          }
          return _PatientCard(patient: patients[index - 1]);
        },
      ),
    );
  }
}

// ── Patient card ──────────────────────────────────────────────────────────────

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.patient});

  final PatientModel patient;

  @override
  Widget build(BuildContext context) {
    final bool deleted = patient.isDeleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetails(context),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: deleted
                            ? AppColors.error.withAlpha(25)
                            : AppColors.primary.withAlpha(20),
                        child: Icon(
                          patient.gender.toLowerCase() == 'male'
                              ? Icons.male
                              : patient.gender.toLowerCase() == 'female'
                              ? Icons.female
                              : Icons.person_outline,
                          color: deleted ? AppColors.error : AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.name,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: deleted
                                        ? AppColors.textSecondary
                                        : AppColors.textPrimary,
                                    decoration: deleted
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${AppTexts.age}: ${patient.age}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (patient.nationalId.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Text(
                                '${AppTexts.nationalId}: ${patient.nationalId}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (patient.bloodGroup.isNotEmpty)
                        StatusBadge(
                          label: patient.bloodGroup,
                          color: AppColors.error,
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  if (patient.notes.isNotEmpty) ...[
                    Text(
                      patient.notes,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        tooltip: AppTexts.editPatientAdmin,
                        onPressed: () => _openEdit(context),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        tooltip: AppTexts.deletePatientAdmin,
                        onPressed: () => _confirmDelete(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (deleted)
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(color: AppColors.error.withAlpha(10)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => AdminPatientFormScreen(patient: patient),
          ),
        )
        .then((_) {
          if (context.mounted) context.read<PatientsCubit>().fetchPatients();
        });
  }

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PatientDetailsScreen(patientId: patient.id),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: AppTexts.deletePatientAdmin,
      message: AppTexts.deletePatientConfirmation,
      confirmLabel: AppTexts.deletePatientAdmin,
    );
    if (confirmed && context.mounted) {
      context.read<PatientsCubit>().deletePatient(patient.id);
    }
  }
}
