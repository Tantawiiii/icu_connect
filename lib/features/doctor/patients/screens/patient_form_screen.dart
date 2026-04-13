import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _notesCtrl = TextEditingController();

  String _gender = 'male';
  String? _bloodGroup;

  final _repository = const HospitalAdmissionsRepository();
  bool _submitting = false;

  static const _maxNameLen = 255;
  static const _maxNationalIdLen = 50;
  static const _maxPhoneLen = 20;

  static const _genders = ['male', 'female'];

  static const _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _nationalIdCtrl.text = e.nationalId;
      _ageCtrl.text = '${e.age}';
      _phoneCtrl.text = e.phone;
      _notesCtrl.text = e.notes;
      final g = e.gender.toLowerCase().trim();
      if (_genders.contains(g)) {
        _gender = g;
      } else {
        _gender = 'male';
      }
      final bg = e.bloodGroup.trim();
      if (bg.isNotEmpty && _bloodGroups.contains(bg)) {
        _bloodGroup = bg;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nationalIdCtrl.dispose();
    _ageCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return AppTexts.nameRequired;
    if (t.length > _maxNameLen) return 'Name must be at most $_maxNameLen characters';
    return null;
  }

  String? _validateNationalId(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'National ID is required';
    if (t.length > _maxNationalIdLen) {
      return 'National ID must be at most $_maxNationalIdLen characters';
    }
    return null;
  }

  String? _validateAge(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Age is required';
    final n = int.tryParse(t);
    if (n == null) return 'Enter a valid age';
    if (n < 0 || n > 150) return 'Age must be between 0 and 150';
    return null;
  }

  String? _validatePhone(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    if (t.length > _maxPhoneLen) {
      return 'Phone must be at most $_maxPhoneLen characters';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final age = int.tryParse(_ageCtrl.text.trim());
    if (age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid age')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final blood = _bloodGroup ?? '';
      if (widget.isEdit) {
        await _repository.updatePatient(
          id: widget.existing!.id,
          name: _nameCtrl.text.trim(),
          nationalId: _nationalIdCtrl.text.trim(),
          age: age,
          gender: _gender,
          phone: _phoneCtrl.text.trim(),
          bloodGroup: blood,
          notes: _notesCtrl.text.trim(),
        );
      } else {
        final created = await _repository.createPatient(
          name: _nameCtrl.text.trim(),
          nationalId: _nationalIdCtrl.text.trim(),
          age: age,
          gender: _gender,
          phone: _phoneCtrl.text.trim(),
          bloodGroup: blood,
          notes: _notesCtrl.text.trim(),
        );
        if (!mounted) return;
        Navigator.of(context).pop<int>(created.id);
        return;
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
              validator: _validateName,
              inputFormatters: [
                LengthLimitingTextInputFormatter(_maxNameLen),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _nationalIdCtrl,
              hintText: AppTexts.nationalId,
              validator: _validateNationalId,
              inputFormatters: [
                LengthLimitingTextInputFormatter(_maxNationalIdLen),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _ageCtrl,
              hintText: AppTexts.age,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _validateAge,
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
                      child: Text(
                        g[0].toUpperCase() + g.substring(1),
                      ),
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
              hintText: '${AppTexts.phone} (optional)',
              keyboardType: TextInputType.phone,
              validator: _validatePhone,
              inputFormatters: [
                LengthLimitingTextInputFormatter(_maxPhoneLen),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _bloodGroup,
              decoration: const InputDecoration(
                labelText: 'Blood group (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              hint: const Text('Select blood group'),
              isExpanded: true,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('—'),
                ),
                ..._bloodGroups.map(
                  (b) => DropdownMenuItem<String?>(
                    value: b,
                    child: Text(b),
                  ),
                ),
              ],
              onChanged: _submitting
                  ? null
                  : (v) => setState(() => _bloodGroup = v),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _notesCtrl,
              hintText: '${AppTexts.notes} (optional)',
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
