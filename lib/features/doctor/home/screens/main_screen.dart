import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/constants/app_colors.dart';

import '../../patients/screens/add_edit_patient_screen.dart';
import '../../patients/screens/patient_list_screen.dart';
import '../widgets/side_drawer.dart';


class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppTexts.appName),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AddEditPatientScreen()),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text(AppTexts.addPatient),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 36),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      drawer: const SideDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: const PatientListScreen(),
        ),
      ),
    );
  }
}
