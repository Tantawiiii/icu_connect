import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/constants/app_colors.dart';

import '../cubit/doctor_hospitals_cubit.dart';
import '../repository/doctor_hospitals_repository.dart';
import '../widgets/doctor_hospitals_section.dart';
import '../../session/doctor_session_display.dart';
import '../screens/request_hospital_screen.dart';
import '../widgets/side_drawer.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DoctorHospitalsCubit(const DoctorHospitalsRepository())..load(),
      child: const _MainView(),
    );
  }
}

class _MainView extends StatefulWidget {
  const _MainView();

  @override
  State<_MainView> createState() => _MainViewState();
}

class _MainViewState extends State<_MainView> {
  @override
  void initState() {
    super.initState();
    DoctorSessionDisplay.hydrate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          SideDrawer.fetchAndApplyProfile();
        }
      },
      appBar: AppBar(
        title: const Text(AppTexts.appName),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      drawer: const SideDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openRequestHospital(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business_outlined),
        label: const Text(AppTexts.requestNewHospital),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<DoctorHospitalsCubit>().refresh(),
        child: DoctorHospitalsSection(),
      ),
    );
  }

  Future<void> _openRequestHospital(BuildContext context) async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const RequestHospitalScreen()),
    );
    if (submitted == true && context.mounted) {
      await context.read<DoctorHospitalsCubit>().refresh();
    }
  }
}
