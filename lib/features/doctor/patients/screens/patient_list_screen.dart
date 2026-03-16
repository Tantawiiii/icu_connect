import 'package:flutter/material.dart';
import 'package:icu_connect/features/doctor/patients/screens/patient_detail_screen.dart';

import '../widgets/patient_card.dart';


class PatientListScreen extends StatelessWidget {
  const PatientListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final List<Map<String, String>> patients = [
      {
        'name': 'Mohamed El-Sayed Ahmed',
        'bed': 'Bed No. 1',
        'date': '28/2/2025',
      },
      {
        'name': 'Ahmed Ali Mahmoud',
        'bed': 'Bed No. 2',
        'date': '01/3/2025',
      },
      {
        'name': 'Sara Hassan',
        'bed': 'Bed No. 3',
        'date': '02/3/2025',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final patient = patients[index];
        return PatientCardWidget(
          name: patient['name']!,
          bedNumber: patient['bed']!,
          admittedDate: patient['date']!,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PatientDetailScreen(
                  name: patient['name']!,
                  bedNumber: patient['bed']!,
                  admittedDate: patient['date']!,
                ),
              ),
            );
          },
          onEdit: () {
            // TODO: Edit
          },
          onDelete: () {
            // TODO: Delete
          },
        );
      },
    );
  }
}
