import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../cubit/patient_form_cubit.dart';
import '../cubit/patient_form_state.dart';
import '../models/patient_model.dart';
import '../models/patient_request_model.dart';

class PatientFormScreen extends StatelessWidget {
  const PatientFormScreen({super.key, this.patient});

  /// Null = create mode, non-null = edit mode.
  final PatientModel? patient;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PatientFormCubit(),
      child: _PatientFormView(patient: patient),
    );
  }
}

class _PatientFormView extends StatefulWidget {
  const _PatientFormView({this.patient});

  final PatientModel? patient;

  @override
  State<_PatientFormView> createState() => _PatientFormViewState();
}

class _PatientFormViewState extends State<_PatientFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _nationalIdCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _notesCtrl;

  String _gender = 'female';
  String _bloodGroup = 'A+';

  bool get _isEdit => widget.patient != null;

  static const _genders = ['female', 'male', 'other'];
  static const _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _nationalIdCtrl = TextEditingController(text: p?.nationalId ?? '');
    _ageCtrl =
        TextEditingController(text: p != null ? p.age.toString() : '');
    _phoneCtrl = TextEditingController(text: p?.phone ?? '');
    _notesCtrl = TextEditingController(text: p?.notes ?? '');
    _gender = p?.gender ?? 'female';
    _bloodGroup = p?.bloodGroup.isNotEmpty == true ? p!.bloodGroup : 'A+';
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final age = int.tryParse(_ageCtrl.text.trim()) ?? 0;

    final request = PatientRequest(
      name: _nameCtrl.text.trim(),
      nationalId: _nationalIdCtrl.text.trim(),
      age: age,
      gender: _gender,
      phone: _phoneCtrl.text.trim().isEmpty
          ? null
          : _phoneCtrl.text.trim(),
      bloodGroup: _bloodGroup,
      notes: _notesCtrl.text.trim(),
    );

    if (_isEdit) {
      context
          .read<PatientFormCubit>()
          .updatePatient(widget.patient!.id, request);
    } else {
      context.read<PatientFormCubit>().createPatient(request);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isEdit ? AppTexts.editPatientAdmin : AppTexts.addPatientAdmin,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<PatientFormCubit, PatientFormState>(
        listener: (context, state) {
          if (state is PatientFormSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pop();
          }
          if (state is PatientFormFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is PatientFormLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader('Basic Information'),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          AppTextField(
                            controller: _nameCtrl,
                            labelText: AppTexts.name,
                            prefixIcon:
                                const Icon(Icons.person_outline),
                            textInputAction: TextInputAction.next,
                            enabled: !isLoading,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _nationalIdCtrl,
                            labelText: AppTexts.nationalId,
                            prefixIcon: const Icon(Icons.badge_outlined),
                            textInputAction: TextInputAction.next,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _ageCtrl,
                            labelText: AppTexts.age,
                            prefixIcon:
                                const Icon(Icons.calendar_today_outlined),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            enabled: !isLoading,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Age is required';
                              }
                              final n = int.tryParse(v.trim());
                              if (n == null || n <= 0) {
                                return 'Enter a valid age';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _phoneCtrl,
                            labelText: AppTexts.phone,
                            prefixIcon:
                                const Icon(Icons.phone_outlined),
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            enabled: !isLoading,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _SectionHeader('Medical Info'),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _gender,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: AppTexts.gender,
                              prefixIcon:
                                  const Icon(Icons.wc_outlined),
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(10)),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                            ),
                            items: _genders
                                .map((g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(
                                          g[0].toUpperCase() +
                                              g.substring(1)),
                                    ))
                                .toList(),
                            onChanged: isLoading
                                ? null
                                : (v) => setState(
                                    () => _gender = v ?? _gender),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            value: _bloodGroup,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: AppTexts.bloodGroup,
                              prefixIcon: const Icon(
                                  Icons.bloodtype_outlined),
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(10)),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                            ),
                            items: _bloodGroups
                                .map((b) => DropdownMenuItem(
                                      value: b,
                                      child: Text(b),
                                    ))
                                .toList(),
                            onChanged: isLoading
                                ? null
                                : (v) => setState(() =>
                                    _bloodGroup = v ?? _bloodGroup),
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _notesCtrl,
                            labelText: AppTexts.notes,
                            prefixIcon:
                                const Icon(Icons.sticky_note_2_outlined),
                            textInputAction: TextInputAction.newline,
                            enabled: !isLoading,
                            keyboardType: TextInputType.multiline,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  AppButton(
                    label: _isEdit
                        ? AppTexts.editPatientAdmin
                        : AppTexts.addPatientAdmin,
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _submit,
                    leadingIcon: Icon(
                      _isEdit
                          ? Icons.save_outlined
                          : Icons.person_add_alt_1_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

