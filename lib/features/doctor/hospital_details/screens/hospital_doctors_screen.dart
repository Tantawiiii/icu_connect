import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/widgets/app_button.dart';

import '../../home/models/doctor_hospital.dart';
import '../cubit/hospital_doctors_cubit.dart';
import '../cubit/hospital_doctors_state.dart';
import '../repository/hospital_doctors_repository.dart';
import '../widgets/add_doctor_bottom_sheet.dart';
import '../widgets/doctor_card.dart';

class HospitalDoctorsScreen extends StatelessWidget {
  const HospitalDoctorsScreen({super.key, required this.hospital});

  final DoctorHospital hospital;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          HospitalDoctorsCubit(const HospitalDoctorsRepository())
            ..load(hospital.id),
      child: _HospitalDoctorsView(hospital: hospital),
    );
  }
}

class _HospitalDoctorsView extends StatelessWidget {
  const _HospitalDoctorsView({required this.hospital});

  final DoctorHospital hospital;

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        (hospital.userStatus.roleInHospital ?? '').toLowerCase().trim() ==
        'admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          AppTexts.doctorsInHospital,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showAddDoctorSheet(context, hospital.id),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text(AppTexts.addDoctor),
            )
          : null,
      body: BlocConsumer<HospitalDoctorsCubit, HospitalDoctorsState>(
        listener: (context, state) {
          if (state is HospitalDoctorsFailure) {
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
          if (state is HospitalDoctorsLoading ||
              state is HospitalDoctorsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HospitalDoctorsFailure) {
            return Center(
              child: AppButton(
                label: AppTexts.retry,
                width: 170,
                onPressed: () =>
                    context.read<HospitalDoctorsCubit>().load(hospital.id),
              ),
            );
          }
          final ready = state as HospitalDoctorsLoaded;
          if (ready.doctors.isEmpty) {
            return RefreshIndicator(
              onRefresh: () =>
                  context.read<HospitalDoctorsCubit>().refresh(hospital.id),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 160),
                  Center(
                    child: Text(
                      AppTexts.noHospitalsAvailable,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                context.read<HospitalDoctorsCubit>().refresh(hospital.id),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(4),
              itemCount: ready.doctors.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final d = ready.doctors[index];
                return DoctorCard(
                  doctor: d,
                  isAdmin: isAdmin,
                  accepting: ready.acceptingIds.contains(d.id),
                  activating: ready.activatingIds.contains(d.id),
                  onAccept: () => context
                      .read<HospitalDoctorsCubit>()
                      .acceptDoctor(hospitalId: hospital.id, doctorId: d.id),
                  onActivate: () => context
                      .read<HospitalDoctorsCubit>()
                      .activateDoctor(hospitalId: hospital.id, doctorId: d.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddDoctorSheet(
    BuildContext context,
    int hospitalId,
  ) async {
    final cubit = context.read<HospitalDoctorsCubit>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => AddDoctorBottomSheet(
        hospitalId: hospitalId,
        onListsChanged: () => cubit.refresh(hospitalId),
      ),
    );
  }
}
