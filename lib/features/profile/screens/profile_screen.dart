import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar and Name
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                 Padding(
                   padding: const EdgeInsets.only(bottom: 20),
                   child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.person, size: 60, color: Colors.white),
                                   ),
                 ),
                 Positioned(
                   bottom: 0,
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                     decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                     ),
                     child: const Text('EDIT', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                   ),
                 )
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'MAHMOUD NASSAR',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 40),

            // Form Fields
            _buildTextField('FIRST NAME'),
            const SizedBox(height: 16),
            _buildTextField('LAST NAME'),
            const SizedBox(height: 16),
            _buildTextField('EMAIL', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildTextField('PHONE NUMBER', keyboardType: TextInputType.phone),
            const SizedBox(height: 40),

            // Save Button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                   Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                   minimumSize: const Size(100, 40),
                ),
                child: const Text(AppTexts.save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, {TextInputType? keyboardType}) {
    return TextField(
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: label,
        filled: true,
        fillColor: const Color(0xFFF5F6FA), // Match wireframe light bg
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
         focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
        ),
        // Adding the shadow effect as seen in wireframe via Container decoration if needed, 
        // but InputDecoration is simpler. Wireframe has internal shadow/neumorphism?
        // Let's stick to simple rounded fields for now.
      ),
    );
  }
}
