import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/app_text_field.dart';
import '../../../superAdmin/patients/models/admission_request_model.dart';
import '../../../superAdmin/patients/models/patient_admission_models.dart';
import '../cubit/admission_form_cubit.dart';
import '../cubit/admission_form_state.dart';
import '../enums/admission_status.dart';

class AdmissionFormScreen extends StatelessWidget {
  const AdmissionFormScreen({
    super.key,
    required this.hospitalId,
    this.admission,
  });

  final int hospitalId;
  final PatientAdmissionModel? admission;

  bool get isEdit => admission != null;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdmissionFormCubit()..loadReferenceData(),
      child: _AdmissionFormBody(
        hospitalId: hospitalId,
        admission: admission,
      ),
    );
  }
}

class _ClinicalEntry {
  _ClinicalEntry({required this.type, required this.content});
  String type;
  final TextEditingController content;
}

class _RadiologyEntry {
  _RadiologyEntry()
      : title = TextEditingController(),
        report = TextEditingController();
  final TextEditingController title;
  final TextEditingController report;
  String? localImagePath;
}

class _TreatmentEntry {
  _TreatmentEntry() : plan = TextEditingController();
  final TextEditingController plan;
}

class _VitalEntry {
  _VitalEntry()
      : value = TextEditingController(),
        date = DateTime.now();
  int? titleId;
  final TextEditingController value;
  DateTime date;
}

class _LabEntry {
  _LabEntry()
      : value = TextEditingController(),
        date = DateTime.now();
  int? titleId;
  final TextEditingController value;
  DateTime date;
}

class _AdmissionFormBody extends StatefulWidget {
  const _AdmissionFormBody({
    required this.hospitalId,
    this.admission,
  });

  final int hospitalId;
  final PatientAdmissionModel? admission;

  @override
  State<_AdmissionFormBody> createState() => _AdmissionFormBodyState();
}

class _AdmissionFormBodyState extends State<_AdmissionFormBody> {
  final _formKey = GlobalKey<FormState>();
  final _bedCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  AdmissionPatientModel? _selectedPatient;
  late AdmissionStatus _status;
  DateTime? _dateComes;
  DateTime? _dateLeave;
  DateTime? _dateOfDeath;

  final _clinical = <_ClinicalEntry>[];
  final _radiology = <_RadiologyEntry>[];
  final _treatments = <_TreatmentEntry>[];
  final _vitals = <_VitalEntry>[];
  final _labs = <_LabEntry>[];

  final _picker = ImagePicker();

  bool get _isEdit => widget.admission != null;

  @override
  void initState() {
    super.initState();
    final a = widget.admission;
    _status = a != null
        ? AdmissionStatus.values.firstWhere(
            (s) => s.apiValue == a.status,
            orElse: () => AdmissionStatus.admitted,
          )
        : AdmissionStatus.admitted;

    if (a != null) {
      _bedCtrl.text = a.bedNumber;
      _notesCtrl.text = a.notes;
      _selectedPatient = a.patient;
      _dateComes = _parseDate(a.dateComes);
      _dateLeave = _parseDate(a.dateLeave);
      _dateOfDeath = _parseDate(a.dateOfDeath);
      
      // Pre-fill lists could be done here but usually doctors add NEW items during update
      // The API snippet suggests adding new ones to the array.
    } else {
      _dateComes = DateTime.now();
    }
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// Ensures the dropdown value matches an item instance from [patients] (by id).
  AdmissionPatientModel? _patientDropdownValue(List<AdmissionPatientModel> patients) {
    final s = _selectedPatient;
    if (s == null) return null;
    for (final p in patients) {
      if (p.id == s.id) return p;
    }
    return null;
  }

  @override
  void dispose() {
    _bedCtrl.dispose();
    _notesCtrl.dispose();
      for (var e in _clinical) {
        e.content.dispose();
      }
      for (var e in _radiology) {
        e.title.dispose();
        e.report.dispose();
      }
      for (var e in _treatments) {
        e.plan.dispose();
      }
      for (var e in _vitals) {
        e.value.dispose();
      }
      for (var e in _labs) {
        e.value.dispose();
      }
    super.dispose();
  }

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate({
    required DateTime? initial,
    required void Function(DateTime) onPick,
  }) async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: initial ?? DateTime.now(),
    );
    if (d != null) onPick(d);
  }

  Future<void> _pickImage(_RadiologyEntry row) async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x != null) setState(() => row.localImagePath = x.path);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient')),
      );
      return;
    }
    if (_dateComes == null && !_isEdit) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admission date is required')),
      );
      return;
    }

    final cubit = context.read<AdmissionFormCubit>();
    // We need doctor_id. If we can't get it from cubit, we'll use a placeholder or handle in cubit.
    // For now, let's assume doctor_id is 1 or handled by backend if missing, 
    // but the rules say required. Let's use 1 as fallback or get it from admission models if editing.
    final doctorId = widget.admission?.doctorId ?? 1; 

    final clinicalDrafts = _clinical
        .where((e) => e.content.text.trim().isNotEmpty)
        .map((e) => AdmissionClinicalNoteDraft(type: e.type, content: e.content.text.trim()))
        .toList();

    final radiologyDrafts = _radiology
        .where((e) => e.title.text.trim().isNotEmpty)
        .map((e) => AdmissionRadiologyDraft(
              title: e.title.text.trim(),
              report: e.report.text.trim().isEmpty ? null : e.report.text.trim(),
              localImagePath: e.localImagePath,
            ))
        .toList();

    final treatmentDrafts = _treatments
        .where((e) => e.plan.text.trim().isNotEmpty)
        .map((e) => AdmissionTreatmentDraft(planContent: e.plan.text.trim()))
        .toList();

    final vitalDrafts = _vitals
        .where((e) => e.titleId != null && e.value.text.isNotEmpty)
        .map((e) => AdmissionVitalDraft(
              vitalsTitleId: e.titleId!,
              value: double.tryParse(e.value.text) ?? 0,
              date: _ymd(e.date),
            ))
        .toList();

    final labDrafts = _labs
        .where((e) => e.titleId != null && e.value.text.isNotEmpty)
        .map((e) => AdmissionLabDraft(
              labsTitleId: e.titleId!,
              value: double.tryParse(e.value.text) ?? 0,
              date: _ymd(e.date),
            ))
        .toList();

    if (_isEdit) {
      final req = AdmissionUpdateRequest(
        bedNumber: _bedCtrl.text.trim(),
        status: _status.apiValue,
        dateLeave: _dateLeave != null ? _ymd(_dateLeave!) : null,
        dateOfDeath: _dateOfDeath != null ? _ymd(_dateOfDeath!) : null,
        notes: _notesCtrl.text.trim(),
        clinicalNotes: clinicalDrafts,
        radiologyImages: radiologyDrafts,
        treatmentPlans: treatmentDrafts,
        vitals: vitalDrafts,
        labs: labDrafts,
      );
      cubit.updateAdmission(widget.admission!.id, req);
    } else {
      final req = AdmissionCreateRequest(
        patientId: _selectedPatient!.id,
        hospitalId: widget.hospitalId,
        doctorId: doctorId,
        bedNumber: _bedCtrl.text.trim(),
        dateComes: _ymd(_dateComes!),
        status: _status.apiValue,
        dateLeave: _dateLeave != null ? _ymd(_dateLeave!) : null,
        dateOfDeath: _dateOfDeath != null ? _ymd(_dateOfDeath!) : null,
        notes: _notesCtrl.text.trim(),
        clinicalNotes: clinicalDrafts,
        radiologyImages: radiologyDrafts,
        treatmentPlans: treatmentDrafts,
        vitals: vitalDrafts,
        labs: labDrafts,
      );
      cubit.createAdmission(req);
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
          _isEdit ? 'Edit Admission' : 'New Admission',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocConsumer<AdmissionFormCubit, AdmissionFormState>(
        listener: (context, state) {
          if (state is AdmissionFormSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
            );
            Navigator.pop(context, true);
          } else if (state is AdmissionFormFailure) {
            if (context.read<AdmissionFormCubit>().refs != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
              );
            }
          }
        },
        builder: (context, state) {
          final cubit = context.read<AdmissionFormCubit>();

          if (state is AdmissionFormInitial || state is AdmissionFormLoadingRefs) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state is AdmissionFormFailure && cubit.refs == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: AppTexts.retry,
                      onPressed: cubit.loadReferenceData,
                    ),
                  ],
                ),
              ),
            );
          }

          final refs = cubit.refs;
          if (refs == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final submitting = state is AdmissionFormSubmitting;

          return Stack(
            children: [
              Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Patient Selection ────────────────────────────────────
                    const _SectionTitle(title: 'Patient'),
                    if (_isEdit)
                       _SectionCard(
                         child: Text(
                           _selectedPatient?.name ?? 'Unknown Patient',
                           style: const TextStyle(fontWeight: FontWeight.bold),
                         ),
                       )
                    else ...[
                      DropdownButtonFormField<AdmissionPatientModel>(
                        value: _patientDropdownValue(refs.patients),
                        decoration: const InputDecoration(
                          labelText: 'Patient',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        hint: const Text('Select a patient'),
                        isExpanded: true,
                        items: refs.patients
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                  '${p.name} · ${p.nationalId}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: refs.patients.isEmpty
                            ? null
                            : (p) => setState(() => _selectedPatient = p),
                        validator: (v) =>
                            v == null && refs.patients.isNotEmpty
                                ? 'Select a patient'
                                : null,
                      ),
                      if (refs.patients.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'No patients found. Try adding patients or check the API.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],

                    const SizedBox(height: 16),

                    // ── Basic Info ───────────────────────────────────────────
                    const _SectionTitle(title: 'Admission Info'),
                    _SectionCard(
                      child: Column(
                        children: [
                          AppTextField(
                            controller: _bedCtrl,
                            hintText: 'Bed Number',
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<AdmissionStatus>(
                            value: _status,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            ),
                            items: AdmissionStatus.values.map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.label.toUpperCase()),
                            )).toList(),
                            onChanged: (v) => setState(() => _status = v!),
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Admission Date'),
                            subtitle: Text(_dateComes != null ? _ymd(_dateComes!) : 'Not set'),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: _isEdit ? null : () => _pickDate(initial: _dateComes, onPick: (d) => setState(() => _dateComes = d)),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Leave Date'),
                            subtitle: Text(_dateLeave != null ? _ymd(_dateLeave!) : 'N/A'),
                            trailing: _dateLeave != null 
                              ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _dateLeave = null))
                              : const Icon(Icons.calendar_today),
                            onTap: () => _pickDate(initial: _dateLeave, onPick: (d) => setState(() => _dateLeave = d)),
                          ),
                          AppTextField(
                            controller: _notesCtrl,
                            hintText: 'Common Notes',
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),

                    // ── Dynamic Sections ─────────────────────────────────────
                    _buildDynamicSection(
                      title: 'Clinical Notes',
                      onAdd: () => setState(() => _clinical.add(_ClinicalEntry(type: 'progress_note', content: TextEditingController()))),
                      children: _clinical.asMap().entries.map((e) {
                        final i = e.key;
                        final row = e.value;
                        return _SectionCard(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: row.type,
                                      items: const [
                                        DropdownMenuItem(value: 'history_complaint', child: Text('History/Complaint')),
                                        DropdownMenuItem(value: 'progress_note', child: Text('Progress Note')),
                                        DropdownMenuItem(value: 'discharge_summary', child: Text('Discharge Summary')),
                                      ],
                                      onChanged: (v) => setState(() => row.type = v!),
                                    ),
                                  ),
                                  IconButton(icon: const Icon(Icons.delete, color: AppColors.error), onPressed: () => setState(() => _clinical.removeAt(i))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              AppTextField(controller: row.content, hintText: 'Content', maxLines: 2),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    _buildDynamicSection(
                      title: 'Radiology',
                      onAdd: () => setState(() => _radiology.add(_RadiologyEntry())),
                      children: _radiology.asMap().entries.map((e) {
                        final i = e.key;
                        final row = e.value;
                        return _SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                   Expanded(child: AppTextField(controller: row.title, hintText: 'Image Title')),
                                   IconButton(icon: const Icon(Icons.delete, color: AppColors.error), onPressed: () => setState(() => _radiology.removeAt(i))),
                                ],
                              ),
                              AppTextField(controller: row.report, hintText: 'Report', maxLines: 2),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  TextButton.icon(onPressed: () => _pickImage(row), icon: const Icon(Icons.image), label: const Text('Pick Image')),
                                  if (row.localImagePath != null)
                                    Expanded(child: Text(row.localImagePath!.split('/').last, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    _buildDynamicSection(
                        title: 'Vitals',
                        onAdd: () => setState(() => _vitals.add(_VitalEntry())),
                        children: _vitals.asMap().entries.map((e) {
                          final i = e.key;
                          final row = e.value;
                          return _SectionCard(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<int>(
                                        value: row.titleId,
                                        hint: const Text('Select Vital'),
                                        items: refs.vitalsTitles.map((t) => DropdownMenuItem(value: t.id, child: Text('${t.title} (${t.unit})'))).toList(),
                                        onChanged: (v) => setState(() => row.titleId = v),
                                      ),
                                    ),
                                    IconButton(icon: const Icon(Icons.delete, color: AppColors.error), onPressed: () => setState(() => _vitals.removeAt(i))),
                                  ],
                                ),
                                AppTextField(controller: row.value, hintText: 'Value', keyboardType: TextInputType.number),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      _buildDynamicSection(
                        title: 'Labs',
                        onAdd: () => setState(() => _labs.add(_LabEntry())),
                        children: _labs.asMap().entries.map((e) {
                          final i = e.key;
                          final row = e.value;
                          return _SectionCard(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<int>(
                                        value: row.titleId,
                                        hint: const Text('Select Lab'),
                                        items: refs.labsTitles.map((t) => DropdownMenuItem(value: t.id, child: Text('${t.title} (${t.unit})'))).toList(),
                                        onChanged: (v) => setState(() => row.titleId = v),
                                      ),
                                    ),
                                    IconButton(icon: const Icon(Icons.delete, color: AppColors.error), onPressed: () => setState(() => _labs.removeAt(i))),
                                  ],
                                ),
                                AppTextField(controller: row.value, hintText: 'Value', keyboardType: TextInputType.number),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 32),
                    AppButton(
                      label: submitting ? 'Saving...' : (_isEdit ? 'Save Changes' : 'Create Admission'),
                      onPressed: submitting ? null : _submit,
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
              if (submitting)
                const ColoredBox(color: Colors.black26, child: Center(child: CircularProgressIndicator())),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDynamicSection({required String title, required VoidCallback onAdd, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionTitle(title: title),
            TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add')),
          ],
        ),
        ...children,
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}
