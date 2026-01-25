import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';

class VitalSignsScreen extends StatelessWidget {
  const VitalSignsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data for Vitals
    final List<Map<String, String>> vitals = [
      {'name': 'CVP', 'value': '15/15'},
      {'name': 'CVP', 'value': '12'},
      {'name': 'ABP', 'value': '100/6'},
      {'name': 'BP', 'value': '90/60'},
      {'name': 'HR', 'value': '85'},
      {'name': 'RR', 'value': '15'},
      {'name': 'SPO2', 'value': '97'},
      {'name': 'O2 Flow', 'value': 'mask'},
      {'name': 'RBS', 'value': '120'},
      {'name': 'TEMP', 'value': '37.2'},
      {'name': 'GCS', 'value': 'E1'},
      {'name': 'Position', 'value': 'FOS'}, // Unclear from wireframe, guessing FOS (Fowler's?)
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bed No. 1   محمد السيد أحمد', // Mock title to match wireframe style
          style: TextStyle(fontSize: 14),
        ),
        centerTitle: true,
        actions: [
          IconButton(
             icon: const Icon(Icons.more_horiz),
             onPressed: () {},
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppTexts.admitted}: 28/2/2025\n${AppTexts.age}: 65',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              
              const Text(
                AppTexts.vitalSigns,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              // Headers
              Row(
                children: [
                  const SizedBox(width: 80), // Space for label
                  Expanded(child: _buildTimeHeader('2AM')),
                  Expanded(child: _buildTimeHeader('6AM')),
                  Expanded(child: _buildTimeHeader('2PM')),
                  const SizedBox(width: 40), // Spacer
                ],
              ),
              const Divider(),

              // List of Vitals
              Expanded(
                child: ListView.separated(
                  itemCount: vitals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final vital = vitals[index];
                    return Row(
                      children: [
                        // Label
                        Container(
                          width: 80,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            vital['name']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        // Values (Mocking repeat values for columns)
                         Expanded(child: Center(child: Text(vital['value']!, style: const TextStyle(fontWeight: FontWeight.bold)))),
                         const Expanded(child: SizedBox()), // Empty column
                         const Expanded(child: SizedBox()), // Empty column
                         const SizedBox(width: 40),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeHeader(String time) {
    return Center(
      child: Text(
        time,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
