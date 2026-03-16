import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';

class LabsScreen extends StatelessWidget {
  const LabsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data for Labs
    final List<Map<String, String>> labs = [
       {'name': 'HGB', 'value': '11.1'},
       {'name': 'TLC', 'value': '12'},
       {'name': 'PLT', 'value': '135'},
       {'name': 'CRP', 'value': '95'},
       {'name': 'PH', 'value': '7.35'},
       {'name': 'PCO2', 'value': '40'},
       {'name': 'HCO3', 'value': '22'},
       {'name': 'LAC', 'value': '1.2'},
       {'name': 'Na', 'value': '130'},
       {'name': 'K', 'value': '4.1'},
       {'name': 'Ca', 'value': '1.16'},
       {'name': 'Urea', 'value': '30'},
       {'name': 'Creat', 'value': '1.5'},
       {'name': 'AST', 'value': '45'},
       {'name': 'AlT', 'value': '35'},
       {'name': 'INR', 'value': '1.1'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bed No. 1   محمد السيد أحمد', // Mock title
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
                AppTexts.labs,
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
                  const SizedBox(width: 60),
                  Expanded(child: _buildTimeHeader('2AM')),
                  Expanded(child: _buildTimeHeader('6AM')),
                  Expanded(child: _buildTimeHeader('2PM')),
                  const SizedBox(width: 40),
                ],
              ),
              const Divider(),

              // List of Labs
              Expanded(
                child: ListView.separated(
                  itemCount: labs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final lab = labs[index];
                    return Row(
                      children: [
                        // Label
                        Container(
                          width: 60,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            lab['name']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        // Values
                         Expanded(child: Center(child: Text(lab['value']!, style: const TextStyle(fontWeight: FontWeight.bold)))),
                         const Expanded(child: SizedBox()),
                         const Expanded(child: SizedBox()),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Add Lab logic
        },
        label: const Text('+Add Lab'),
        backgroundColor: AppColors.primary,
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
