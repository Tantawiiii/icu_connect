import 'package:flutter/material.dart';

import 'admission_form_section_title.dart';

class AdmissionFormDynamicSection extends StatelessWidget {
  const AdmissionFormDynamicSection({
    super.key,
    required this.title,
    required this.onAdd,
    required this.children,
  });

  final String title;
  final VoidCallback onAdd;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AdmissionFormSectionTitle(title: title),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        ...children,
      ],
    );
  }
}
