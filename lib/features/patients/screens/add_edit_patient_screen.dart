import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';

class AddEditPatientScreen extends StatelessWidget {
  final bool isEdit;
  const AddEditPatientScreen({super.key, this.isEdit = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Patient' : AppTexts.addPatient.replaceAll('+ ', '')), // Stripping logic for title
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Profile Image Placeholder
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.surface,
                  child: const Icon(Icons.person, size: 60, color: AppColors.textSecondary),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Form Fields
            _buildTextField(context, 'First Name'),
            const SizedBox(height: 16),
             _buildTextField(context, 'Last Name'),
            const SizedBox(height: 16),
             _buildTextField(context, 'Email', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
             _buildTextField(context, 'Phone Number', keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
             _buildTextField(context, AppTexts.bedNo),
            const SizedBox(height: 16),
             _buildTextField(context, AppTexts.age, keyboardType: TextInputType.number),
             const SizedBox(height: 40),
             
             // Save Button
             ElevatedButton(
               onPressed: () {
                 Navigator.pop(context);
               },
               child: const Text(AppTexts.save),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, String label, {TextInputType? keyboardType}) {
    return TextField(
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: label.toUpperCase(),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
