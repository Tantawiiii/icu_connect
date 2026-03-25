import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/app_text_field.dart';
import 'package:icu_connect/features/doctor/hospital_details/repository/hospital_admissions_repository.dart';
import 'package:icu_connect/features/superAdmin/patients/models/patient_admission_models.dart';

/// Create (`POST /patients`) or update (`PUT /patients/{id}`).
class PatientFormScreen extends StatefulWidget {
  const PatientFormScreen({super.key, this.existing});

  /// When non-null, screen performs PUT for this patient.
  final AdmissionPatientModel? existing;

  bool get isEdit => existing != null;

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nationalIdCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bloodCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _gender = 'male';

  final _repository = const HospitalAdmissionsRepository();
  bool _submitting = false;

  static const _genders = ['male', 'female', 'other'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _nationalIdCtrl.text = e.nationalId;
      _ageCtrl.text = '${e.age}';
      _phoneCtrl.text = e.phone;
      _bloodCtrl.text = e.bloodGroup;
      _notesCtrl.text = e.notes;
      final g = e.gender.toLowerCase();
      if (_genders.contains(g)) _gender = g;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nationalIdCtrl.dispose();
    _ageCtrl.dispose();
    _phoneCtrl.dispose();
    _bloodCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final age = int.tryParse(_ageCtrl.text.trim());
    if (age == null || age < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid age')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      if (widget.isEdit) {
        await _repository.updatePatient(
          id: widget.existing!.id,
          name: _nameCtrl.text.trim(),
          nationalId: _nationalIdCtrl.text.trim(),
          age: age,
          gender: _gender,
          phone: _phoneCtrl.text.trim(),
          bloodGroup: _bloodCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
        );
      } else {
        await _repository.createPatient(
          name: _nameCtrl.text.trim(),
          nationalId: _nationalIdCtrl.text.trim(),
          age: age,
          gender: _gender,
          phone: _phoneCtrl.text.trim(),
          bloodGroup: _bloodCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on NetworkException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          widget.isEdit ? AppTexts.editPatientAdmin : AppTexts.addPatientAdmin,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(
              controller: _nameCtrl,
              hintText: AppTexts.name,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? AppTexts.nameRequired : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _nationalIdCtrl,
              hintText: AppTexts.nationalId,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'National ID is required' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _ageCtrl,
              hintText: AppTexts.age,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Age is required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(
                labelText: AppTexts.gender,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              items: _genders
                  .map(
                    (g) => DropdownMenuItem(
                      value: g,
                      child: Text(g[0].toUpperCase() + g.substring(1)),
                    ),
                  )
                  .toList(),
              onChanged: _submitting
                  ? null
                  : (v) => setState(() => _gender = v ?? 'male'),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _phoneCtrl,
              hintText: AppTexts.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _bloodCtrl,
              hintText: AppTexts.bloodGroup,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _notesCtrl,
              hintText: AppTexts.notes,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: _submitting
                  ? '…'
                  : (widget.isEdit ? 'Update patient' : AppTexts.addPatientAdmin),
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
