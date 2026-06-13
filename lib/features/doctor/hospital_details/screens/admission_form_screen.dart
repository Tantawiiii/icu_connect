import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/app_text_field.dart';
import 'package:icu_connect/features/doctor/patients/screens/patient_form_screen.dart';
import '../../../superAdmin/patients/models/admission_request_model.dart';
import '../../../superAdmin/patients/models/patient_admission_models.dart';
import '../cubit/admission_form_cubit.dart';
import '../cubit/admission_form_state.dart';
import '../enums/admission_status.dart';
import '../widgets/admission_form_dynamic_section.dart';
import '../widgets/admission_form_essentials_section.dart';
import '../widgets/admission_form_section_card.dart';
import '../widgets/radiology_path_utils.dart';

class AdmissionFormScreen extends StatelessWidget {
  const AdmissionFormScreen({
    super.key,
    required this.hospitalId,
    this.admission,
    this.initialBedNumber,
    this.hospitalGroupId,
    this.initialPatientId,
  });

  final int hospitalId;
  final PatientAdmissionModel? admission;

  /// Pre-fills the bed field when creating a new admission (e.g. from hospital bed grid).
  final String? initialBedNumber;

  /// Sent as `hospital_group_id` when creating/updating (e.g. ward/group from hospital details).
  final int? hospitalGroupId;

  /// Pre-selects the patient when opening after creating one from the bed flow.
  final int? initialPatientId;

  bool get isEdit => admission != null;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdmissionFormCubit()
        ..loadReferenceData(ensurePatientId: initialPatientId),
      child: _AdmissionFormBody(
        hospitalId: hospitalId,
        admission: admission,
        initialBedNumber: initialBedNumber,
        hospitalGroupId: hospitalGroupId,
        initialPatientId: initialPatientId,
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

  /// Local gallery paths — images and videos; each becomes one `radiology_images[]` row on submit.
  final List<String> localMediaPaths = [];
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

class _MedicationEntry {
  _MedicationEntry()
      : title = TextEditingController(),
        value = TextEditingController(),
        duration = TextEditingController();
  String type = 'other';
  final TextEditingController title;
  final TextEditingController value;
  final TextEditingController duration;
}

class _EchoEntry {
  _EchoEntry() : text = TextEditingController();
  final TextEditingController text;
}

class _UltrasoundEntry {
  _UltrasoundEntry() : text = TextEditingController();
  final TextEditingController text;
}

class _CultureEntry {
  _CultureEntry()
      : title = TextEditingController(),
        note = TextEditingController();
  final TextEditingController title;
  final TextEditingController note;
}

class _AdmissionFormBody extends StatefulWidget {
  const _AdmissionFormBody({
    required this.hospitalId,
    this.admission,
    this.initialBedNumber,
    this.hospitalGroupId,
    this.initialPatientId,
  });

  final int hospitalId;
  final PatientAdmissionModel? admission;
  final String? initialBedNumber;
  final int? hospitalGroupId;
  final int? initialPatientId;

  @override
  State<_AdmissionFormBody> createState() => _AdmissionFormBodyState();
}

class _AdmissionFormBodyState extends State<_AdmissionFormBody> {
  final _formKey = GlobalKey<FormState>();
  final _bedCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  AdmissionPatientModel? _selectedPatient;
  bool _initialPatientApplied = false;
  late AdmissionStatus _status;
  DateTime? _dateComes;
  DateTime? _dateLeave;
  DateTime? _dateOfDeath;

  final _clinical = <_ClinicalEntry>[];
  final _radiology = <_RadiologyEntry>[];
  final _treatments = <_TreatmentEntry>[];
  final _vitals = <_VitalEntry>[];
  final _labs = <_LabEntry>[];
  final _medications = <_MedicationEntry>[];
  final _echoes = <_EchoEntry>[];
  final _ultrasounds = <_UltrasoundEntry>[];
  final _cultures = <_CultureEntry>[];

  final _picker = ImagePicker();
  bool _optionalSectionsExpanded = false;

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

    } else {
      _dateComes = DateTime.now();
      final preset = widget.initialBedNumber?.trim();
      if (preset != null && preset.isNotEmpty) {
        _bedCtrl.text = preset;
      }
    }
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  void _applyInitialPatient(List<AdmissionPatientModel> patients) {
    if (_initialPatientApplied || widget.initialPatientId == null) return;
    for (final patient in patients) {
      if (patient.id == widget.initialPatientId) {
        _initialPatientApplied = true;
        setState(() => _selectedPatient = patient);
        return;
      }
    }
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
      for (var e in _medications) {
        e.title.dispose();
        e.value.dispose();
        e.duration.dispose();
      }
      for (var e in _echoes) {
        e.text.dispose();
      }
      for (var e in _ultrasounds) {
        e.text.dispose();
      }
      for (var e in _cultures) {
        e.title.dispose();
        e.note.dispose();
      }
    super.dispose();
  }

  String _sqlDateTime(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}:'
      '${d.second.toString().padLeft(2, '0')}';

  Future<void> _pickDateTime({
    required DateTime? initial,
    required void Function(DateTime) onPick,
    DateTime? notBefore,
  }) async {
    final base = initial ?? DateTime.now();
    final minDay = notBefore != null
        ? DateTime(notBefore.year, notBefore.month, notBefore.day)
        : DateTime(2000);
    var pickDay = DateTime(base.year, base.month, base.day);
    if (pickDay.isBefore(minDay)) pickDay = minDay;

    final d = await showDatePicker(
      context: context,
      firstDate: minDay,
      lastDate: DateTime(2100),
      initialDate: pickDay,
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (t == null || !mounted) return;
    final result = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    if (notBefore != null && result.isBefore(notBefore)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppTexts.admissionLeaveNotBeforeComes),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    onPick(result);
  }

  Future<void> _addRadiologyImages(_RadiologyEntry row) async {
    final files = await _picker.pickMultiImage(imageQuality: 80);
    if (files.isEmpty || !mounted) return;
    setState(() {
      row.localMediaPaths.addAll(files.map((f) => f.path));
    });
  }

  Future<void> _addRadiologyVideo(_RadiologyEntry row) async {
    final x = await _picker.pickVideo(source: ImageSource.gallery);
    if (x == null || !mounted) return;
    setState(() => row.localMediaPaths.add(x.path));
  }

  Future<void> _openAddPatient() async {
    final newId = await Navigator.of(context).push<int?>(
      MaterialPageRoute(builder: (_) => const PatientFormScreen()),
    );
    if (newId == null || !mounted) return;

    final cubit = context.read<AdmissionFormCubit>();
    try {
      await cubit.refreshPatients(ensurePatientId: newId);
    } on NetworkException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
      return;
    }

    final list = cubit.refs?.patients;
    if (list == null || !mounted) return;

    AdmissionPatientModel? match;
    for (final p in list) {
      if (p.id == newId) {
        match = p;
        break;
      }
    }
    if (match != null) {
      setState(() => _selectedPatient = match);
    }
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

    final admissionRef = _dateComes ??
        (_isEdit && widget.admission != null
            ? _parseDate(widget.admission!.dateComes)
            : null);

    if (_dateLeave != null &&
        admissionRef != null &&
        _dateLeave!.isBefore(admissionRef)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppTexts.admissionLeaveNotBeforeComes),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_dateOfDeath != null &&
        admissionRef != null &&
        _dateOfDeath!.isBefore(admissionRef)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppTexts.admissionDeathNotBeforeComes),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final cubit = context.read<AdmissionFormCubit>();
    final doctorId =
        cubit.refs?.currentDoctorId ?? widget.admission?.doctorId ?? 1;

    final clinicalDrafts = _clinical
        .where((e) => e.content.text.trim().isNotEmpty)
        .map(
          (e) => AdmissionClinicalNoteDraft(
            type: e.type,
            content: e.content.text.trim(),
          ),
        )
        .toList();

    final radiologyDrafts = <AdmissionRadiologyDraft>[];
    for (final e in _radiology.where((r) => r.title.text.trim().isNotEmpty)) {
      final title = e.title.text.trim();
      final report =
          e.report.text.trim().isEmpty ? null : e.report.text.trim();
      if (e.localMediaPaths.isEmpty) {
        radiologyDrafts.add(
          AdmissionRadiologyDraft(title: title, report: report),
        );
      } else {
        for (final path in e.localMediaPaths) {
          radiologyDrafts.add(
            AdmissionRadiologyDraft(
              title: title,
              report: report,
              localImagePath: path,
            ),
          );
        }
      }
    }

    final treatmentDrafts = _treatments
        .where((e) => e.plan.text.trim().isNotEmpty)
        .map((e) => AdmissionTreatmentDraft(planContent: e.plan.text.trim()))
        .toList();

    final vitalDrafts = _vitals
        .where((e) => e.titleId != null && e.value.text.isNotEmpty)
        .map(
          (e) => AdmissionVitalDraft(
            vitalsTitleId: e.titleId!,
            value: double.tryParse(e.value.text) ?? 0,
            date: _sqlDateTime(e.date),
          ),
        )
        .toList();

    final labDrafts = _labs
        .where((e) => e.titleId != null && e.value.text.isNotEmpty)
        .map(
          (e) => AdmissionLabDraft(
            labsTitleId: e.titleId!,
            value: double.tryParse(e.value.text) ?? 0,
            date: _sqlDateTime(e.date),
          ),
        )
        .toList();

    final medicationDrafts = _medications
        .where((e) => e.title.text.trim().isNotEmpty)
        .map(
          (e) => AdmissionMedicationDraft(
            type: e.type,
            title: e.title.text.trim(),
            value: e.value.text.trim(),
            duration: e.duration.text.trim(),
          ),
        )
        .toList();

    final echoDrafts = _echoes
        .where((e) => e.text.text.trim().isNotEmpty)
        .map((e) => AdmissionEchoDraft(text: e.text.text.trim()))
        .toList();

    final ultrasoundDrafts = _ultrasounds
        .where((e) => e.text.text.trim().isNotEmpty)
        .map((e) => AdmissionUltrasoundDraft(text: e.text.text.trim()))
        .toList();

    final cultureDrafts = _cultures
        .where((e) => e.title.text.trim().isNotEmpty)
        .map(
          (e) => AdmissionCultureDraft(
            title: e.title.text.trim(),
            note: e.note.text.trim(),
          ),
        )
        .toList();

    if (_isEdit) {
      final req = AdmissionUpdateRequest(
        bedNumber: _bedCtrl.text.trim(),
        hospitalGroupId: widget.hospitalGroupId,
        status: _status.apiValue,
        dateLeave:
            _dateLeave != null ? _sqlDateTime(_dateLeave!) : null,
        dateOfDeath:
            _dateOfDeath != null ? _sqlDateTime(_dateOfDeath!) : null,
        notes: _notesCtrl.text.trim(),
        clinicalNotes: clinicalDrafts,
        radiologyImages: radiologyDrafts,
        treatmentPlans: treatmentDrafts,
        vitals: vitalDrafts,
        labs: labDrafts,
        medications: medicationDrafts,
        echoes: echoDrafts,
        ultrasounds: ultrasoundDrafts,
        cultures: cultureDrafts,
      );
      cubit.updateAdmission(widget.admission!.id, req);
    } else {
      final req = AdmissionCreateRequest(
        patientId: _selectedPatient!.id,
        hospitalId: widget.hospitalId,
        doctorId: doctorId,
        hospitalGroupId: widget.hospitalGroupId,
        bedNumber: _bedCtrl.text.trim(),
        dateComes: _sqlDateTime(_dateComes!),
        status: _status.apiValue,
        dateLeave:
            _dateLeave != null ? _sqlDateTime(_dateLeave!) : null,
        dateOfDeath:
            _dateOfDeath != null ? _sqlDateTime(_dateOfDeath!) : null,
        notes: _notesCtrl.text.trim(),
        clinicalNotes: clinicalDrafts,
        radiologyImages: radiologyDrafts,
        treatmentPlans: treatmentDrafts,
        vitals: vitalDrafts,
        labs: labDrafts,
        medications: medicationDrafts,
        echoes: echoDrafts,
        ultrasounds: ultrasoundDrafts,
        cultures: cultureDrafts,
      );
      cubit.createAdmission(req);
    }
  }

  String _appBarTitle() {
    final name = _selectedPatient?.name.trim();
    if (name != null && name.isNotEmpty) return name;
    return _isEdit ? AppTexts.editAdmission : AppTexts.createAdmission;
  }
  List<Widget> _buildOptionalSections(
    AdmissionFormRefsReady refs,
    bool submitting,
  ) {
    return [
      AdmissionFormDynamicSection(
        title: 'Clinical Notes',
        onAdd: () => setState(
          () => _clinical.add(
            _ClinicalEntry(
              type: 'progress_note',
              content: TextEditingController(),
            ),
          ),
        ),
        children: _clinical.asMap().entries.map((e) {
          final i = e.key;
          final row = e.value;
          return AdmissionFormSectionCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: row.type,
                        items: const [
                          DropdownMenuItem(
                            value: 'history_complaint',
                            child: Text('History/Complaint'),
                          ),
                          DropdownMenuItem(
                            value: 'progress_note',
                            child: Text('Progress Note'),
                          ),
                          DropdownMenuItem(
                            value: 'discharge_summary',
                            child: Text('Discharge Summary'),
                          ),
                        ],
                        onChanged: (v) => setState(() => row.type = v!),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.error),
                      onPressed: () => setState(() => _clinical.removeAt(i)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: row.content,
                  hintText: 'Content',
                  maxLines: 2,
                ),
              ],
            ),
          );
        }).toList(),
      ),
      AdmissionFormDynamicSection(
        title: 'Radiology',
        onAdd: () => setState(() => _radiology.add(_RadiologyEntry())),
        children: _radiology.asMap().entries.map((e) {
          final i = e.key;
          final row = e.value;
          return AdmissionFormSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: row.title,
                        hintText: 'Image Title',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.error),
                      onPressed: () => setState(() => _radiology.removeAt(i)),
                    ),
                  ],
                ),
                AppTextField(
                  controller: row.report,
                  hintText: 'Report',
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed:
                          submitting ? null : () => _addRadiologyImages(row),
                      icon: const Icon(Icons.photo_library_outlined, size: 20),
                      label: const Text('Add images'),
                    ),
                    TextButton.icon(
                      onPressed:
                          submitting ? null : () => _addRadiologyVideo(row),
                      icon: const Icon(Icons.video_library_outlined, size: 20),
                      label: const Text('Add video'),
                    ),
                  ],
                ),
                if (row.localMediaPaths.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: row.localMediaPaths.asMap().entries.map((me) {
                      final idx = me.key;
                      final path = me.value;
                      final isVideo = isRadiologyPathVideo(path);
                      return InputChip(
                        avatar: Icon(
                          isVideo
                              ? Icons.videocam_outlined
                              : Icons.image_outlined,
                          size: 18,
                          color: isVideo ? AppColors.error : AppColors.primary,
                        ),
                        label: Text(
                          path.split('/').last,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onDeleted: submitting
                            ? null
                            : () =>
                                setState(() => row.localMediaPaths.removeAt(idx)),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
      AdmissionFormDynamicSection(
        title: 'Treatment plans',
        onAdd: () => setState(() => _treatments.add(_TreatmentEntry())),
        children: _treatments.asMap().entries.map((e) {
          final i = e.key;
          final row = e.value;
          return AdmissionFormSectionCard(
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: row.plan,
                    hintText: 'Plan content',
                    maxLines: 3,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  onPressed: () => setState(() => _treatments.removeAt(i)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
      AdmissionFormDynamicSection(
        title: 'Medications',
        onAdd: () => setState(() => _medications.add(_MedicationEntry())),
        children: _medications.asMap().entries.map((e) {
          final i = e.key;
          final row = e.value;
          return AdmissionFormSectionCard(
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'infusion',
                            child: Text('Infusion'),
                          ),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
                        ],
                        onChanged: (v) =>
                            setState(() => row.type = v ?? 'other'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.error),
                      onPressed: () => setState(() => _medications.removeAt(i)),
                    ),
                  ],
                ),
                AppTextField(controller: row.title, hintText: 'Title'),
                const SizedBox(height: 8),
                AppTextField(
                  controller: row.value,
                  hintText: 'Value (e.g. dose, rate)',
                ),
                const SizedBox(height: 8),
                AppTextField(controller: row.duration, hintText: 'Duration'),
              ],
            ),
          );
        }).toList(),
      ),
      AdmissionFormDynamicSection(
        title: 'Echo',
        onAdd: () => setState(() => _echoes.add(_EchoEntry())),
        children: _echoes.asMap().entries.map((e) {
          final i = e.key;
          final row = e.value;
          return AdmissionFormSectionCard(
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: row.text,
                    hintText: 'Findings',
                    maxLines: 4,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  onPressed: () => setState(() => _echoes.removeAt(i)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
      AdmissionFormDynamicSection(
        title: 'Ultrasound',
        onAdd: () => setState(() => _ultrasounds.add(_UltrasoundEntry())),
        children: _ultrasounds.asMap().entries.map((e) {
          final i = e.key;
          final row = e.value;
          return AdmissionFormSectionCard(
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: row.text,
                    hintText: 'Findings',
                    maxLines: 4,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  onPressed: () => setState(() => _ultrasounds.removeAt(i)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
      AdmissionFormDynamicSection(
        title: 'Cultures',
        onAdd: () => setState(() => _cultures.add(_CultureEntry())),
        children: _cultures.asMap().entries.map((e) {
          final i = e.key;
          final row = e.value;
          return AdmissionFormSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: row.title,
                        hintText: 'Title',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.error),
                      onPressed: () => setState(() => _cultures.removeAt(i)),
                    ),
                  ],
                ),
                AppTextField(controller: row.note, hintText: 'Note', maxLines: 3),
              ],
            ),
          );
        }).toList(),
      ),
      AdmissionFormDynamicSection(
        title: 'Vitals',
        onAdd: () => setState(() => _vitals.add(_VitalEntry())),
        children: _vitals.asMap().entries.map((e) {
          final i = e.key;
          final row = e.value;
          return AdmissionFormSectionCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: row.titleId,
                        hint: const Text('Select Vital'),
                        items: refs.vitalsTitles
                            .map(
                              (t) => DropdownMenuItem(
                                value: t.id,
                                child: Text('${t.title} (${t.unit})'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => row.titleId = v),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.error),
                      onPressed: () => setState(() => _vitals.removeAt(i)),
                    ),
                  ],
                ),
                AppTextField(
                  controller: row.value,
                  hintText: 'Value',
                  keyboardType: TextInputType.number,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Measured at', style: TextStyle(fontSize: 13)),
                  subtitle: Text(_sqlDateTime(row.date)),
                  trailing: const Icon(Icons.schedule, size: 20),
                  onTap: () => _pickDateTime(
                    initial: row.date,
                    onPick: (d) => setState(() => row.date = d),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
      AdmissionFormDynamicSection(
        title: 'Labs',
        onAdd: () => setState(() => _labs.add(_LabEntry())),
        children: _labs.asMap().entries.map((e) {
          final i = e.key;
          final row = e.value;
          return AdmissionFormSectionCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: row.titleId,
                        hint: const Text('Select Lab'),
                        items: refs.labsTitles
                            .map(
                              (t) => DropdownMenuItem(
                                value: t.id,
                                child: Text('${t.title} (${t.unit})'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => row.titleId = v),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.error),
                      onPressed: () => setState(() => _labs.removeAt(i)),
                    ),
                  ],
                ),
                AppTextField(
                  controller: row.value,
                  hintText: 'Value',
                  keyboardType: TextInputType.number,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Measured at', style: TextStyle(fontSize: 13)),
                  subtitle: Text(_sqlDateTime(row.date)),
                  trailing: const Icon(Icons.schedule, size: 20),
                  onTap: () => _pickDateTime(
                    initial: row.date,
                    onPick: (d) => setState(() => row.date = d),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdmissionFormCubit, AdmissionFormState>(
      listener: (context, state) {
        if (state is AdmissionFormRefsReady) {
          _applyInitialPatient(state.patients);
        }
        if (state is AdmissionFormSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        } else if (state is AdmissionFormFailure) {
          if (context.read<AdmissionFormCubit>().refs != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },
      builder: (context, state) {
        final cubit = context.read<AdmissionFormCubit>();

        if (state is AdmissionFormInitial ||
            state is AdmissionFormLoadingRefs) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.textPrimary),
              title: Text(
                _appBarTitle(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (state is AdmissionFormFailure && cubit.refs == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.textPrimary),
              title: Text(
                _appBarTitle(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: Center(
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
            ),
          );
        }

        final refs = cubit.refs;
        if (refs == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.textPrimary),
              title: Text(
                _appBarTitle(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final submitting = state is AdmissionFormSubmitting;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            title: Text(
              _appBarTitle(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AppButton(
              label: submitting
                  ? 'Saving...'
                  : (_isEdit ? AppTexts.save : AppTexts.createAdmission),
              onPressed: submitting ? null : _submit,
            ),
          ),
          body: Stack(
            children: [
              Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    AdmissionFormEssentialsSection(
                      isEdit: _isEdit,
                      submitting: submitting,
                      bedCtrl: _bedCtrl,
                      notesCtrl: _notesCtrl,
                      status: _status,
                      dateComes: _dateComes,
                      dateLeave: _dateLeave,
                      dateOfDeath: _dateOfDeath,
                      patients: refs.patients,
                      selectedPatient: _selectedPatient,
                      hospitalGroupId: widget.hospitalGroupId,
                      onPatientChanged: (patient) =>
                          setState(() => _selectedPatient = patient),
                      onAddPatient: _openAddPatient,
                      onStatusChanged: (status) => setState(
                        () => _status = status ?? AdmissionStatus.admitted,
                      ),
                      onPickDateComes: () => _pickDateTime(
                        initial: _dateComes,
                        onPick: (date) => setState(() {
                          _dateComes = date;
                          if (_dateLeave != null &&
                              _dateLeave!.isBefore(date)) {
                            _dateLeave = null;
                          }
                        }),
                      ),
                      onPickDateLeave: () {
                        if (_dateComes == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(AppTexts.admissionSetComesFirst),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        _pickDateTime(
                          initial: _dateLeave ?? _dateComes,
                          notBefore: _dateComes,
                          onPick: (date) => setState(() => _dateLeave = date),
                        );
                      },
                      onClearDateLeave: () =>
                          setState(() => _dateLeave = null),
                      onPickDateOfDeath: () {
                        if (_dateComes == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(AppTexts.admissionSetComesFirst),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        _pickDateTime(
                          initial: _dateOfDeath ?? _dateComes,
                          notBefore: _dateComes,
                          onPick: (date) =>
                              setState(() => _dateOfDeath = date),
                        );
                      },
                      onClearDateOfDeath: () =>
                          setState(() => _dateOfDeath = null),
                      bedValidator: (value) =>
                          (value?.trim() ?? '').isEmpty ? 'Required' : null,
                      patientValidator: (patient) =>
                          patient == null ? 'Select a patient' : null,
                    ),
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        key: const PageStorageKey('admission_optional_sections'),
                        initiallyExpanded: _optionalSectionsExpanded,
                        onExpansionChanged: (expanded) => setState(
                          () => _optionalSectionsExpanded = expanded,
                        ),
                        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                        childrenPadding: const EdgeInsets.only(bottom: 8),
                        shape: const Border(),
                        collapsedShape: const Border(),
                        title: const Text(
                          AppTexts.admissionOptionalRecords,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: const Text(
                          AppTexts.admissionOptionalRecordsHint,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        children: _buildOptionalSections(refs, submitting),
                      ),
                    ),
                  ],
                ),
              ),
              if (submitting)
                const ColoredBox(
                  color: Colors.black26,
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }
}
