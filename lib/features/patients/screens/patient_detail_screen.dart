import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/features/patients/screens/vital_signs_screen.dart'; // Will be created next
import 'package:icu_connect/features/patients/screens/labs_screen.dart'; // Will be created next

class PatientDetailScreen extends StatelessWidget {
  final String name;
  final String bedNumber;
  final String admittedDate;

  const PatientDetailScreen({
    super.key,
    required this.name,
    required this.bedNumber,
    required this.admittedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Patient Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    bedNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${AppTexts.admitted} : $admittedDate',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 16),
                const Text(
                  '${AppTexts.age} : 65', // Mock age
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const Divider(height: 24),

            // Content Sections
            _buildSectionContainer(
              title: AppTexts.historyAndComplaint,
              child: const SizedBox(height: 60), // Placeholder content height
            ),
            
            _buildSectionContainer(
              title: AppTexts.radiology,
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActionButton(AppTexts.viewImages),
                      _buildActionButton(AppTexts.addImage),
                    ],
                  )
                ],
              ),
            ),
            
            _buildSectionContainer(
              title: AppTexts.progressNote,
              child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: _buildActionButton(AppTexts.addNote),
                  )),
            ),

            // Quick Links to Vitals and Labs (Represented as sections or buttons)
            // For now, I'll add buttons to navigate to them as they are separate screens in wireframe
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => const VitalSignsScreen()));
                    },
                    child: const Text('Vital Signs'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => const LabsScreen()));
                    },
                    child: const Text('Labs'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContainer({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE0E0E0).withOpacity(0.5), // Light grey fill
             borderRadius: BorderRadius.circular(16),
             border: Border.all(color: Colors.transparent), // No border visible in wireframe for these boxes
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildActionButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
