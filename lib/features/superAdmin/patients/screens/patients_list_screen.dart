import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          AppTexts.patientsLabel,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
            return _ErrorView(
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
        .push(MaterialPageRoute(
          builder: (_) => PatientFormScreen(patient: patient),
        ))
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
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.personal_injury_outlined,
                size: 56, color: AppColors.secondary),
            SizedBox(height: 12),
            Text('No patients found',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<PatientsCubit>().fetchPatients(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${patients.length} '
              '${patients.length == 1 ? 'patient' : 'patients'}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          ...patients.map((p) => _PatientCard(patient: p)),
        ],
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
                          color: deleted
                              ? AppColors.error
                              : AppColors.primary,
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
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
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            if (patient.nationalId.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Text(
                                '${AppTexts.nationalId}: ${patient.nationalId}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (patient.bloodGroup.isNotEmpty)
                        _Badge(
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
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.accent, size: 20),
                        tooltip: AppTexts.editPatientAdmin,
                        onPressed: () => _openEdit(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error, size: 20),
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
                  child: ColoredBox(
                    color: AppColors.error.withAlpha(10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => PatientFormScreen(patient: patient),
        ))
        .then((_) {
      if (context.mounted) context.read<PatientsCubit>().fetchPatients();
    });
  }

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PatientDetailsScreen(patientId: patient.id),
    ));
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppTexts.deletePatientAdmin),
        content: const Text(AppTexts.deletePatientConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppTexts.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<PatientsCubit>().deletePatient(patient.id);
            },
            child: const Text(AppTexts.deletePatientAdmin),
          ),
        ],
      ),
    );
  }
}

// ── Badge ─────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

