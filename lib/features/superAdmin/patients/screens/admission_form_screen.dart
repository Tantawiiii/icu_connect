import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../cubit/admission_form_cubit.dart';
import '../cubit/admission_form_state.dart';
import '../models/admission_request_model.dart';
import '../models/patient_admission_models.dart';

class AdmissionFormScreen extends StatelessWidget {
  const AdmissionFormScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    this.admission,
  });

  final int patientId;
  final String patientName;
  final PatientAdmissionModel? admission;

  bool get isEdit => admission != null;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdmissionFormCubit()..loadReferenceData(),
      child: _AdmissionFormBody(
        patientId: patientId,
        patientName: patientName,
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
    required this.patientId,
    required this.patientName,
    this.admission,
  });

  final int patientId;
  final String patientName;
  final PatientAdmissionModel? admission;

  @override
  State<_AdmissionFormBody> createState() => _AdmissionFormBodyState();
}

class _AdmissionFormBodyState extends State<_AdmissionFormBody> {
  static const _statuses = [
    'active',
    'inactive',
    'admitted',
    'discharged',
    'leaves_ama',
    'deceased',
    'referred',
  ];

  static const _clinicalTypes = [
    'history_complaint',
    'progress_note',
    'discharge_summary',
  ];

  final _formKey = GlobalKey<FormState>();
  final _bedCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  int? _hospitalId;
  int? _doctorId;
  late String _status;

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
    _status = a?.status ?? 'admitted';
    if (a != null) {
      _bedCtrl.text = a.bedNumber;
      _notesCtrl.text = a.notes;
      _hospitalId = a.hospital?.id ?? a.hospitalId;
      _doctorId = a.doctor?.id ?? a.doctorId;
      _dateComes = _parseDate(a.dateComes);
      _dateLeave = _parseDate(a.dateLeave);
      _dateOfDeath = _parseDate(a.dateOfDeath);
    }
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  @override
  void dispose() {
    _bedCtrl.dispose();
    _notesCtrl.dispose();
    for (final c in _clinical) {
      c.content.dispose();
    }
    for (final r in _radiology) {
      r.title.dispose();
      r.report.dispose();
    }
    for (final t in _treatments) {
      t.plan.dispose();
    }
    for (final v in _vitals) {
      v.value.dispose();
    }
    for (final l in _labs) {
      l.value.dispose();
    }
    super.dispose();
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x != null) setState(() => row.localImagePath = x.path);
  }

  void _submit(AdmissionFormRefsReady refs) {
    if (!_formKey.currentState!.validate()) return;

    if (!_isEdit) {
      if (_hospitalId == null || _doctorId == null || _dateComes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Select hospital, doctor, and admission date'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final clinical = _clinical
          .where((e) => e.content.text.trim().isNotEmpty)
          .map(
            (e) => AdmissionClinicalNoteDraft(
              type: e.type,
              content: e.content.text.trim(),
            ),
          )
          .toList();

      final radiology = _radiology
          .where((e) => e.title.text.trim().isNotEmpty)
          .map(
            (e) => AdmissionRadiologyDraft(
              title: e.title.text.trim(),
              report: e.report.text.trim().isEmpty ? null : e.report.text.trim(),
              localImagePath: e.localImagePath,
            ),
          )
          .toList();

      final plans = _treatments
          .where((e) => e.plan.text.trim().isNotEmpty)
          .map(
            (e) => AdmissionTreatmentDraft(planContent: e.plan.text.trim()),
          )
          .toList();

      final vitals = <AdmissionVitalDraft>[];
      for (final v in _vitals) {
        if (v.titleId == null) continue;
        final val = double.tryParse(v.value.text.trim());
        if (val == null) continue;
        vitals.add(AdmissionVitalDraft(
          vitalsTitleId: v.titleId!,
          value: val,
          date: _ymd(v.date),
        ));
      }

      final labs = <AdmissionLabDraft>[];
      for (final l in _labs) {
        if (l.titleId == null) continue;
        final val = double.tryParse(l.value.text.trim());
        if (val == null) continue;
        labs.add(AdmissionLabDraft(
          labsTitleId: l.titleId!,
          value: val,
          date: _ymd(l.date),
        ));
      }

      final req = AdmissionCreateRequest(
        patientId: widget.patientId,
        hospitalId: _hospitalId!,
        doctorId: _doctorId!,
        bedNumber: _bedCtrl.text.trim(),
        dateComes: _ymd(_dateComes!),
        status: _status,
        dateLeave: _dateLeave != null ? _ymd(_dateLeave!) : null,
        dateOfDeath: _dateOfDeath != null ? _ymd(_dateOfDeath!) : null,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        clinicalNotes: clinical,
        radiologyImages: radiology,
        treatmentPlans: plans,
        vitals: vitals,
        labs: labs,
      );

      context.read<AdmissionFormCubit>().createAdmission(req);
      return;
    }

    final a = widget.admission!;

    final clinical = _clinical
        .where((e) => e.content.text.trim().isNotEmpty)
        .map(
          (e) => AdmissionClinicalNoteDraft(
            type: e.type,
            content: e.content.text.trim(),
          ),
        )
        .toList();

    final radiology = _radiology
        .where((e) => e.title.text.trim().isNotEmpty)
        .map(
          (e) => AdmissionRadiologyDraft(
            title: e.title.text.trim(),
            report: e.report.text.trim().isEmpty ? null : e.report.text.trim(),
            localImagePath: e.localImagePath,
          ),
        )
        .toList();

    final plans = _treatments
        .where((e) => e.plan.text.trim().isNotEmpty)
        .map(
          (e) => AdmissionTreatmentDraft(planContent: e.plan.text.trim()),
        )
        .toList();

    final vitals = <AdmissionVitalDraft>[];
    for (final v in _vitals) {
      if (v.titleId == null) continue;
      final val = double.tryParse(v.value.text.trim());
      if (val == null) continue;
      vitals.add(AdmissionVitalDraft(
        vitalsTitleId: v.titleId!,
        value: val,
        date: _ymd(v.date),
      ));
    }

    final labs = <AdmissionLabDraft>[];
    for (final l in _labs) {
      if (l.titleId == null) continue;
      final val = double.tryParse(l.value.text.trim());
      if (val == null) continue;
      labs.add(AdmissionLabDraft(
        labsTitleId: l.titleId!,
        value: val,
        date: _ymd(l.date),
      ));
    }

    final update = AdmissionUpdateRequest(
      bedNumber: _bedCtrl.text.trim(),
      status: _status,
      dateLeave: _dateLeave != null ? _ymd(_dateLeave!) : null,
      dateOfDeath: _dateOfDeath != null ? _ymd(_dateOfDeath!) : null,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      clinicalNotes: clinical,
      radiologyImages: radiology,
      treatmentPlans: plans,
      vitals: vitals,
      labs: labs,
    );

    context.read<AdmissionFormCubit>().updateAdmission(a.id, update);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isEdit ? AppTexts.editAdmission : AppTexts.addAdmission,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<AdmissionFormCubit, AdmissionFormState>(
        listener: (context, state) {
          if (state is AdmissionFormSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pop(true);
          }
          if (state is AdmissionFormFailure) {
            final cubit = context.read<AdmissionFormCubit>();
            if (cubit.refs != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
        builder: (context, state) {
          final cubit = context.read<AdmissionFormCubit>();

          if (state is AdmissionFormLoadingRefs ||
              state is AdmissionFormInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
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
                      onPressed: () =>
                          context.read<AdmissionFormCubit>().loadReferenceData(),
                    ),
                  ],
                ),
              ),
            );
          }

          final refs = cubit.refs;
          if (refs == null) {
            return const SizedBox.shrink();
          }

          final submitting = state is AdmissionFormSubmitting;

          return Stack(
            children: [
              Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      widget.patientName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${AppTexts.patientsLabel} ID: ${widget.patientId}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_isEdit && widget.admission != null) ...[
                      _SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Admission context (read-only)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hospital: ${widget.admission!.hospital?.name ?? '#${widget.admission!.hospitalId}'}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            Text(
                              'Doctor: ${widget.admission!.doctor?.name ?? '#${widget.admission!.doctorId}'}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            Text(
                              'Admitted: ${_dateComes != null ? _ymd(_dateComes!) : AppTexts.notAvailable}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (!_isEdit) ...[
                      DropdownButtonFormField<int>(
                        value: _hospitalId,
                        decoration: const InputDecoration(
                          labelText: 'Hospital',
                          border: OutlineInputBorder(),
                        ),
                        items: refs.hospitals
                            .map(
                              (h) => DropdownMenuItem(
                                value: h.id,
                                child: Text(h.name),
                              ),
                            )
                            .toList(),
                        onChanged: submitting
                            ? null
                            : (v) => setState(() => _hospitalId = v),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _doctorId,
                        decoration: const InputDecoration(
                          labelText: 'Doctor (user)',
                          border: OutlineInputBorder(),
                        ),
                        items: refs.users
                            .map(
                              (u) => DropdownMenuItem(
                                value: u.id,
                                child: Text('${u.name} (${u.role})'),
                              ),
                            )
                            .toList(),
                        onChanged: submitting
                            ? null
                            : (v) => setState(() => _doctorId = v),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Admission date *'),
                        subtitle: Text(
                          _dateComes != null
                              ? _ymd(_dateComes!)
                              : 'Select date',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: submitting
                            ? null
                            : () => _pickDate(
                                  initial: _dateComes,
                                  onPick: (d) => setState(() => _dateComes = d),
                                ),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                    ],
                    AppTextField(
                      controller: _bedCtrl,
                      hintText: 'Bed number',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _statuses.contains(_status) ? _status : 'admitted',
                      decoration: const InputDecoration(
                        labelText: AppTexts.status,
                        border: OutlineInputBorder(),
                      ),
                      items: _statuses
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.replaceAll('_', ' ')),
                            ),
                          )
                          .toList(),
                      onChanged: submitting
                          ? null
                          : (v) => setState(() => _status = v ?? 'admitted'),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Discharge date'),
                      subtitle: Text(
                        _dateLeave != null
                            ? _ymd(_dateLeave!)
                            : AppTexts.notAvailable,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_dateLeave != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: submitting
                                  ? null
                                  : () => setState(() => _dateLeave = null),
                            ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                      onTap: submitting
                          ? null
                          : () => _pickDate(
                                initial: _dateLeave,
                                onPick: (d) => setState(() => _dateLeave = d),
                              ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date of death'),
                      subtitle: Text(
                        _dateOfDeath != null
                            ? _ymd(_dateOfDeath!)
                            : AppTexts.notAvailable,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_dateOfDeath != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: submitting
                                  ? null
                                  : () => setState(() => _dateOfDeath = null),
                            ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                      onTap: submitting
                          ? null
                          : () => _pickDate(
                                initial: _dateOfDeath,
                                onPick: (d) => setState(() => _dateOfDeath = d),
                              ),
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _notesCtrl,
                      hintText: 'Notes',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    _buildDynamicSection(
                      title: 'Clinical notes (optional)',
                      onAdd: submitting
                          ? null
                          : () => setState(
                                () => _clinical.add(
                                  _ClinicalEntry(
                                    type: _clinicalTypes.first,
                                    content: TextEditingController(),
                                  ),
                                ),
                              ),
                      children: _clinical.asMap().entries.map((e) {
                        final i = e.key;
                        final row = e.value;
                        return _SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: row.type,
                                      decoration: const InputDecoration(
                                        labelText: 'Type',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      items: _clinicalTypes
                                          .map(
                                            (t) => DropdownMenuItem(
                                              value: t,
                                              child: Text(
                                                t.replaceAll('_', ' '),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: submitting
                                          ? null
                                          : (v) => setState(
                                                () => row.type = v ?? row.type,
                                              ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: submitting
                                        ? null
                                        : () {
                                            row.content.dispose();
                                            setState(
                                              () => _clinical.removeAt(i),
                                            );
                                          },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              AppTextField(
                                controller: row.content,
                                hintText: 'Content',
                                maxLines: 3,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    _buildDynamicSection(
                      title: 'Radiology (optional)',
                      onAdd: submitting
                          ? null
                          : () => setState(() {
                                _radiology.add(_RadiologyEntry());
                              }),
                      children: _radiology.asMap().entries.map((e) {
                        final i = e.key;
                        final row = e.value;
                        return _SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Image',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: submitting
                                        ? null
                                        : () {
                                            row.title.dispose();
                                            row.report.dispose();
                                            setState(
                                              () => _radiology.removeAt(i),
                                            );
                                          },
                                  ),
                                ],
                              ),
                              AppTextField(
                                controller: row.title,
                                hintText: 'Title *',
                              ),
                              const SizedBox(height: 8),
                              AppTextField(
                                controller: row.report,
                                hintText: 'Report',
                                maxLines: 3,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: submitting
                                        ? null
                                        : () => _pickImage(row),
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Pick image'),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      row.localImagePath == null
                                          ? 'No file'
                                          : row.localImagePath!
                                              .split('/')
                                              .last,
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    _buildDynamicSection(
                      title: 'Treatment plans (optional)',
                      onAdd: submitting
                          ? null
                          : () => setState(() {
                                _treatments.add(_TreatmentEntry());
                              }),
                      children: _treatments.asMap().entries.map((e) {
                        final i = e.key;
                        final row = e.value;
                        return _SectionCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: AppTextField(
                                  controller: row.plan,
                                  hintText: 'Plan content',
                                  maxLines: 4,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: submitting
                                    ? null
                                    : () {
                                        row.plan.dispose();
                                        setState(
                                          () => _treatments.removeAt(i),
                                        );
                                      },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    _buildDynamicSection(
                      title: 'Vitals (optional)',
                      onAdd: submitting
                          ? null
                          : () => setState(() {
                                _vitals.add(_VitalEntry());
                              }),
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
                                      decoration: const InputDecoration(
                                        labelText: 'Vital',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      items: refs.vitalTitles
                                          .map(
                                            (t) => DropdownMenuItem(
                                              value: t.id,
                                              child: Text(
                                                '${t.title} (${t.unit})',
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: submitting
                                          ? null
                                          : (v) => setState(
                                                () => row.titleId = v,
                                              ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: submitting
                                        ? null
                                        : () {
                                            row.value.dispose();
                                            setState(
                                              () => _vitals.removeAt(i),
                                            );
                                          },
                                  ),
                                ],
                              ),
                              AppTextField(
                                controller: row.value,
                                hintText: 'Value',
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Date'),
                                subtitle: Text(_ymd(row.date)),
                                trailing: const Icon(Icons.calendar_today),
                                onTap: submitting
                                    ? null
                                    : () => _pickDate(
                                          initial: row.date,
                                          onPick: (d) =>
                                              setState(() => row.date = d),
                                        ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    _buildDynamicSection(
                      title: 'Labs (optional)',
                      onAdd: submitting
                          ? null
                          : () => setState(() {
                                _labs.add(_LabEntry());
                              }),
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
                                      decoration: const InputDecoration(
                                        labelText: 'Lab',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      items: refs.labTitles
                                          .map(
                                            (t) => DropdownMenuItem(
                                              value: t.id,
                                              child: Text(
                                                '${t.title} (${t.unit})',
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: submitting
                                          ? null
                                          : (v) => setState(
                                                () => row.titleId = v,
                                              ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: submitting
                                        ? null
                                        : () {
                                            row.value.dispose();
                                            setState(() => _labs.removeAt(i));
                                          },
                                  ),
                                ],
                              ),
                              AppTextField(
                                controller: row.value,
                                hintText: 'Value',
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Date'),
                                subtitle: Text(_ymd(row.date)),
                                trailing: const Icon(Icons.calendar_today),
                                onTap: submitting
                                    ? null
                                    : () => _pickDate(
                                          initial: row.date,
                                          onPick: (d) =>
                                              setState(() => row.date = d),
                                        ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: _isEdit ? AppTexts.save : AppTexts.createAdmission,
                      onPressed: submitting ? null : () => _submit(refs),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              if (submitting)
                const ColoredBox(
                  color: Colors.black26,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDynamicSection({
    required String title,
    required VoidCallback? onAdd,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (onAdd != null)
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add'),
              ),
          ],
        ),
        ...children,
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}
