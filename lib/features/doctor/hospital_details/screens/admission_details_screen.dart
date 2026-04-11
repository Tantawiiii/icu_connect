import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/core/widgets/app_button.dart';

import '../../../superAdmin/patients/models/admission_request_model.dart';
import '../../../superAdmin/patients/models/patient_admission_models.dart';
import '../enums/admission_status.dart';
import '../repository/hospital_admissions_repository.dart';
import '../widgets/admission_details_culture_card.dart';
import '../widgets/admission_details_empty_hint.dart';
import '../widgets/admission_details_formatters.dart';
import '../widgets/admission_details_generic_add_form.dart';
import '../widgets/admission_details_info_section.dart';
import '../widgets/admission_details_medication_card.dart';
import '../widgets/admission_details_measurement_section.dart';
import '../widgets/admission_details_meta_chip.dart';
import '../widgets/admission_details_note_card.dart';
import '../widgets/admission_details_patient_header_section.dart';
import '../widgets/admission_details_radiology_card.dart';
import '../widgets/admission_details_section_container.dart';
import '../widgets/admission_details_simple_text_card.dart';
import '../widgets/admission_details_treatment_plan_card.dart';
import '../widgets/pending_measurement_entry.dart';

class AdmissionDetailsScreen extends StatefulWidget {
  const AdmissionDetailsScreen({super.key, required this.admissionId});
  final int admissionId;

  @override
  State<AdmissionDetailsScreen> createState() => _AdmissionDetailsScreenState();
}

class _AdmissionDetailsScreenState extends State<AdmissionDetailsScreen> {
  late Future<PatientAdmissionModel> _admissionFuture;
  final _repo = const HospitalAdmissionsRepository();


  final _patientEditFormKey = GlobalKey<FormState>();
  TextEditingController? _patientNameCtrl;
  TextEditingController? _patientNationalIdCtrl;
  TextEditingController? _patientAgeCtrl;
  TextEditingController? _patientPhoneCtrl;
  TextEditingController? _patientNotesCtrl;
  String _patientEditGender = 'male';
  String? _patientEditBloodGroup;
  bool _editingPatient = false;
  bool _savingPatient = false;

  final _admissionEditFormKey = GlobalKey<FormState>();
  TextEditingController? _bedCtrl;
  TextEditingController? _admissionNotesCtrl;
  AdmissionStatus _editStatus = AdmissionStatus.admitted;
  DateTime? _editDateComes;
  DateTime? _editDateLeave;
  DateTime? _editDateOfDeath;
  bool _editingAdmission = false;
  bool _savingAdmission = false;


  bool _addingVital = false;
  bool _savingVital = false;
  PendingMeasurementEntry? _pendingVital;
  List<MeasurementTitleModel> _vitalsTitles = [];


  bool _addingLab = false;
  bool _savingLab = false;
  PendingMeasurementEntry? _pendingLab;
  List<MeasurementTitleModel> _labsTitles = [];


  String? _addingSection;
  bool _savingGeneric = false;
  final Map<String, TextEditingController> _genericCtrls = {};
  String? _pendingType;
  final List<String> _radiologyLocalPaths = [];
  final ImagePicker _imagePicker = ImagePicker();

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
    _loadAdmission();
    _loadTitles();
  }

  @override
  void dispose() {
    _disposePatientCtrls();
    _disposeAdmissionCtrls();
    _pendingVital?.valueCtrl.dispose();
    _pendingLab?.valueCtrl.dispose();
    for (var c in _genericCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _disposePatientCtrls() {
    _patientNameCtrl?.dispose();
    _patientNationalIdCtrl?.dispose();
    _patientAgeCtrl?.dispose();
    _patientPhoneCtrl?.dispose();
    _patientNotesCtrl?.dispose();
    _patientNameCtrl = _patientNationalIdCtrl = _patientAgeCtrl =
        _patientPhoneCtrl = _patientNotesCtrl = null;
  }

  void _disposeAdmissionCtrls() {
    _bedCtrl?.dispose();
    _admissionNotesCtrl?.dispose();
    _bedCtrl = _admissionNotesCtrl = null;
  }

  void _loadAdmission() {
    setState(() {
      _admissionFuture = _repo.getAdmission(widget.admissionId);
    });
  }

  Future<void> _refreshAdmission() async {
    if (_editingPatient) _cancelPatientEdit();
    if (_editingAdmission) _cancelAdmissionEdit();
    final f = _repo.getAdmission(widget.admissionId);
    setState(() => _admissionFuture = f);
    await f;
  }

  Future<void> _loadTitles() async {
    try {
      final v = await _repo.listVitalsTitles();
      final l = await _repo.listLabsTitles();
      if (mounted) {
        setState(() {
          _vitalsTitles = v;
          _labsTitles = l;
        });
      }
    } catch (_) {}
  }

  // ── Generic Section Add ──────────────────────────────────────────────────
  void _startAddGeneric(String section, {String? defaultType}) {
    for (var c in _genericCtrls.values) {
      c.dispose();
    }
    _genericCtrls.clear();
    _radiologyLocalPaths.clear();
    _pendingType = defaultType;
    setState(() => _addingSection = section);
  }

  void _cancelAddGeneric() {
    setState(() {
      _addingSection = null;
      _radiologyLocalPaths.clear();
    });
  }

  Future<void> _pickRadiologyImages() async {
    final files = await _imagePicker.pickMultiImage(imageQuality: 80);
    if (files.isEmpty || !mounted) return;
    setState(() => _radiologyLocalPaths.addAll(files.map((f) => f.path)));
  }

  Future<void> _pickRadiologyVideo() async {
    final x = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (x == null || !mounted) return;
    setState(() => _radiologyLocalPaths.add(x.path));
  }

  TextEditingController _getCtrl(String key) {
    return _genericCtrls.putIfAbsent(key, () => TextEditingController());
  }

  Future<void> _saveGenericAdd() async {
    if (_addingSection == null) return;
    setState(() => _savingGeneric = true);
    try {
      final body = <String, dynamic>{};
      final section = _addingSection;

      if (section == 'med') {
        body['medications'] = [
          {
            'type': _pendingType ?? 'other',
            'title': _getCtrl('title').text.trim(),
            'value': _getCtrl('value').text.trim(),
            'duration': _getCtrl('duration').text.trim(),
          },
        ];
      } else if (section == 'clinical_note') {
        body['clinical_notes'] = [
          {
            'type': _pendingType ?? 'progress_note',
            'content': _getCtrl('content').text.trim(),
          },
        ];
      } else if (section == 'radiology') {
        final title = _getCtrl('title').text.trim();
        final report = _getCtrl('report').text.trim();
        if (title.isEmpty) {
          _showSnack('Title is required', isError: true);
          return;
        }
        if (_radiologyLocalPaths.isNotEmpty) {
          final drafts = _radiologyLocalPaths
              .map(
                (path) => AdmissionRadiologyDraft(
                  title: title,
                  report: report.isEmpty ? null : report,
                  localImagePath: path,
                ),
              )
              .toList();
          final fd = await AdmissionUpdateRequest(
            radiologyImages: drafts,
          ).toFormData();
          await _repo.updateAdmission(widget.admissionId, fd);
        } else {
          await _repo.updateAdmissionRaw(widget.admissionId, {
            'radiology_images': [
              {
                'title': title,
                if (report.isNotEmpty) 'report': report,
              },
            ],
          });
        }
      } else if (section == 'echo') {
        body['echoes'] = [
          {'text': _getCtrl('text').text.trim()},
        ];
      } else if (section == 'us') {
        body['ultrasounds'] = [
          {'text': _getCtrl('text').text.trim()},
        ];
      } else if (section == 'culture') {
        body['cultures'] = [
          {
            'title': _getCtrl('title').text.trim(),
            'note': _getCtrl('note').text.trim(),
          },
        ];
      } else if (section == 'plan') {
        body['treatment_plans'] = [
          {'plan_content': _getCtrl('plan').text.trim()},
        ];
      }

      await _repo.updateAdmissionRaw(widget.admissionId, body);
      if (!mounted) return;
      _showSnack('Entry added');
      _cancelAddGeneric();
      _loadAdmission();
    } on NetworkException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _savingGeneric = false);
    }
  }

  Future<void> _deleteItem(String sectionKey, int itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repo.updateAdmissionRaw(widget.admissionId, {
        sectionKey: [
          {'id': itemId, '_delete': true},
        ],
      });
      if (!mounted) return;
      _showSnack('Entry deleted');
      _loadAdmission();
    } on NetworkException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    }
  }

  void _beginPatientEdit(AdmissionPatientModel p) {
    _disposePatientCtrls();
    _patientNameCtrl = TextEditingController(text: p.name);
    _patientNationalIdCtrl = TextEditingController(text: p.nationalId);
    _patientAgeCtrl = TextEditingController(text: '${p.age}');
    _patientPhoneCtrl = TextEditingController(text: p.phone);
    _patientNotesCtrl = TextEditingController(text: p.notes);
    final g = p.gender.toLowerCase().trim();
    _patientEditGender = _genders.contains(g) ? g : 'male';
    final bg = p.bloodGroup.trim();
    _patientEditBloodGroup = bg.isNotEmpty && _bloodGroups.contains(bg)
        ? bg
        : null;
    setState(() => _editingPatient = true);
  }

  void _cancelPatientEdit() {
    setState(() {
      _disposePatientCtrls();
      _editingPatient = false;
    });
  }

  Future<void> _savePatientEdit(int patientId) async {
    if (!(_patientEditFormKey.currentState?.validate() ?? false)) return;
    final age = int.tryParse(_patientAgeCtrl?.text.trim() ?? '');
    if (age == null) {
      _showSnack('Enter a valid age', isError: true);
      return;
    }
    setState(() => _savingPatient = true);
    try {
      await _repo.updatePatient(
        id: patientId,
        name: _patientNameCtrl!.text.trim(),
        nationalId: _patientNationalIdCtrl!.text.trim(),
        age: age,
        gender: _patientEditGender,
        phone: _patientPhoneCtrl!.text.trim(),
        bloodGroup: _patientEditBloodGroup ?? '',
        notes: _patientNotesCtrl!.text.trim(),
      );
      if (!mounted) return;
      _showSnack('Patient updated');
      _cancelPatientEdit();
      _loadAdmission();
    } on NetworkException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _savingPatient = false);
    }
  }


  void _beginAdmissionEdit(PatientAdmissionModel a) {
    _disposeAdmissionCtrls();
    _bedCtrl = TextEditingController(text: a.bedNumber);
    _admissionNotesCtrl = TextEditingController(text: a.notes);
    _editStatus = AdmissionStatus.values.firstWhere(
      (s) => s.apiValue == a.status,
      orElse: () => AdmissionStatus.admitted,
    );
    _editDateComes = a.dateComes != null
        ? DateTime.tryParse(a.dateComes!)
        : null;
    _editDateLeave = a.dateLeave != null
        ? DateTime.tryParse(a.dateLeave!)
        : null;
    _editDateOfDeath = a.dateOfDeath != null
        ? DateTime.tryParse(a.dateOfDeath!)
        : null;
    setState(() => _editingAdmission = true);
  }

  void _cancelAdmissionEdit() {
    setState(() {
      _disposeAdmissionCtrls();
      _editingAdmission = false;
    });
  }

  Future<void> _saveAdmissionEdit(PatientAdmissionModel a) async {
    if (!(_admissionEditFormKey.currentState?.validate() ?? false)) return;
    setState(() => _savingAdmission = true);
    try {
      final body = <String, dynamic>{
        'bed_number': _bedCtrl!.text.trim(),
        'status': _editStatus.apiValue,
        'notes': _admissionNotesCtrl!.text.trim(),
        if (_editDateLeave != null)
          'date_leave': admissionDetailsSqlDateTime(_editDateLeave!),
        if (_editDateOfDeath != null)
          'date_of_death': admissionDetailsSqlDateTime(_editDateOfDeath!),
      };

      await _repo.updateAdmissionRaw(a.id, body);
      if (!mounted) return;
      _showSnack('Admission updated');
      _cancelAdmissionEdit();
      _loadAdmission();
    } on NetworkException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _savingAdmission = false);
    }
  }

  void _startAddVital([int? titleId]) {
    _pendingVital?.valueCtrl.dispose();
    _pendingVital = PendingMeasurementEntry();
    if (titleId != null) _pendingVital!.titleId = titleId;
    setState(() => _addingVital = true);
  }

  void _cancelAddVital() {
    _pendingVital?.valueCtrl.dispose();
    _pendingVital = null;
    setState(() => _addingVital = false);
  }

  Future<void> _saveVital() async {
    final p = _pendingVital;
    if (p == null || p.titleId == null || p.valueCtrl.text.trim().isEmpty) {
      _showSnack('Select a vital and enter a value', isError: true);
      return;
    }
    setState(() => _savingVital = true);
    try {
      await _repo.updateAdmissionRaw(widget.admissionId, {
        'vitals': [
          {
            'vitals_title_id': p.titleId,
            'value': double.tryParse(p.valueCtrl.text.trim()) ?? 0,
            'date': admissionDetailsSqlDateTime(p.date),
          },
        ],
      });
      if (!mounted) return;
      _showSnack('Vital added');
      _cancelAddVital();
      _loadAdmission();
    } on NetworkException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _savingVital = false);
    }
  }


  void _startAddLab([int? titleId]) {
    _pendingLab?.valueCtrl.dispose();
    _pendingLab = PendingMeasurementEntry();
    if (titleId != null) _pendingLab!.titleId = titleId;
    setState(() => _addingLab = true);
  }

  void _cancelAddLab() {
    _pendingLab?.valueCtrl.dispose();
    _pendingLab = null;
    setState(() => _addingLab = false);
  }

  Future<void> _saveLab() async {
    final p = _pendingLab;
    if (p == null || p.titleId == null || p.valueCtrl.text.trim().isEmpty) {
      _showSnack('Select a lab and enter a value', isError: true);
      return;
    }
    setState(() => _savingLab = true);
    try {
      await _repo.updateAdmissionRaw(widget.admissionId, {
        'labs': [
          {
            'labs_title_id': p.titleId,
            'value': double.tryParse(p.valueCtrl.text.trim()) ?? 0,
            'date': admissionDetailsSqlDateTime(p.date),
          },
        ],
      });
      if (!mounted) return;
      _showSnack('Lab result added');
      _cancelAddLab();
      _loadAdmission();
    } on NetworkException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _savingLab = false);
    }
  }

  void _deleteAdmission() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Admission'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _repo.deleteAdmission(widget.admissionId);
      if (!mounted) return;
      _showSnack('Admission deleted');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to delete: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _pickDateTime({
    required DateTime? initial,
    required void Function(DateTime) onPick,
  }) async {
    final base = initial ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: DateTime(base.year, base.month, base.day),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (t == null || !mounted) return;
    onPick(DateTime(d.year, d.month, d.day, t.hour, t.minute));
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
          'Admission #${widget.admissionId}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          FutureBuilder<PatientAdmissionModel>(
            future: _admissionFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final admission = snapshot.data!;
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
                onSelected: (val) {
                  if (val == 'edit_patient') {
                    final p = admission.patient;
                    if (p != null) _beginPatientEdit(p);
                  } else if (val == 'edit_admission') {
                    _beginAdmissionEdit(admission);
                  } else if (val == 'delete') {
                    _deleteAdmission();
                  }
                },
                itemBuilder: (ctx) => [
                  if (admission.patient != null)
                    PopupMenuItem(
                      value: 'edit_patient',
                      child: Text(AppTexts.editPatientAdmin),
                    ),
                  PopupMenuItem(
                    value: 'edit_admission',
                    child: Text(AppTexts.editAdmission),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<PatientAdmissionModel>(
          future: _admissionFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (snapshot.hasError) {
              final msg = snapshot.error is NetworkException
                  ? (snapshot.error as NetworkException).message
                  : 'Failed to load admission.';
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 42,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        msg,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: AppTexts.retry,
                        onPressed: _loadAdmission,
                      ),
                    ],
                  ),
                ),
              );
            }

            final admission = snapshot.data;
            if (admission == null) return const SizedBox.shrink();

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refreshAdmission,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Patient header ───────────────────────────────────────
                    AdmissionDetailsPatientHeaderSection(
                      admission: admission,
                      editing: _editingPatient,
                      saving: _savingPatient,
                      formKey: _patientEditFormKey,
                      nameCtrl: _patientNameCtrl,
                      nationalIdCtrl: _patientNationalIdCtrl,
                      ageCtrl: _patientAgeCtrl,
                      phoneCtrl: _patientPhoneCtrl,
                      notesCtrl: _patientNotesCtrl,
                      gender: _patientEditGender,
                      bloodGroup: _patientEditBloodGroup,
                      genders: _genders,
                      bloodGroups: _bloodGroups,
                      onGenderChanged: (v) =>
                          setState(() => _patientEditGender = v ?? 'male'),
                      onBloodGroupChanged: (v) =>
                          setState(() => _patientEditBloodGroup = v),
                      onBeginEdit: admission.patient != null
                          ? () => _beginPatientEdit(admission.patient!)
                          : null,
                      onCancel: _cancelPatientEdit,
                      onSave: admission.patient != null
                          ? () => _savePatientEdit(admission.patient!.id)
                          : null,
                    ),
                    const Divider(height: 24),

                    // ── Admission info (inline edit) ─────────────────────────
                    AdmissionDetailsInfoSection(
                      admission: admission,
                      editing: _editingAdmission,
                      saving: _savingAdmission,
                      formKey: _admissionEditFormKey,
                      bedCtrl: _bedCtrl,
                      notesCtrl: _admissionNotesCtrl,
                      editStatus: _editStatus,
                      editDateComes: _editDateComes,
                      editDateLeave: _editDateLeave,
                      editDateOfDeath: _editDateOfDeath,
                      onStatusChanged: (v) => setState(
                        () => _editStatus = v ?? AdmissionStatus.admitted,
                      ),
                      onPickDateLeave: () => _pickDateTime(
                        initial: _editDateLeave,
                        onPick: (d) => setState(() => _editDateLeave = d),
                      ),
                      onClearDateLeave: () =>
                          setState(() => _editDateLeave = null),
                      onPickDateOfDeath: () => _pickDateTime(
                        initial: _editDateOfDeath,
                        onPick: (d) => setState(() => _editDateOfDeath = d),
                      ),
                      onClearDateOfDeath: () =>
                          setState(() => _editDateOfDeath = null),
                      onCancel: _cancelAdmissionEdit,
                      onSave: () => _saveAdmissionEdit(admission),
                    ),
                    const SizedBox(height: 8),

                    // ── Clinical Notes ───────────────────────────────────────
                    AdmissionDetailsSectionContainer(
                      title: 'Clinical Notes',
                      headerAction: _addingSection == 'clinical_note'
                          ? null
                          : IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              onPressed: () => _startAddGeneric(
                                'clinical_note',
                                defaultType: 'progress_note',
                              ),
                            ),
                      child: Column(
                        children: [
                          if (_addingSection == 'clinical_note')
                            AdmissionDetailsGenericAddForm(
                              title: 'Add Clinical Note',
                              saving: _savingGeneric,
                              onCancel: _cancelAddGeneric,
                              onSave: _saveGenericAdd,
                              typeLabel: 'Note Type',
                              typeValue: _pendingType,
                              types: const [
                                'history_complaint',
                                'progress_note',
                                'discharge_summary',
                                'other',
                              ],
                              onTypeChanged: (v) =>
                                  setState(() => _pendingType = v),
                              fields: [
                                AdmissionDetailsFormFieldSpec(
                                  hint: 'Content',
                                  controller: _getCtrl('content'),
                                  maxLines: 5,
                                  isRequired: true,
                                ),
                              ],
                            ),
                          if (admission.clinicalNotes.isEmpty &&
                              _addingSection != 'clinical_note')
                            const AdmissionDetailsEmptyHint(
                              'No clinical notes recorded.',
                            )
                          else
                            ...admission.clinicalNotes.map(
                              (n) => AdmissionDetailsNoteCard(
                                note: n,
                                onDelete: () =>
                                    _deleteItem('clinical_notes', n.id),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ── Radiology ────────────────────────────────────────────
                    AdmissionDetailsSectionContainer(
                      title: 'Radiology',
                      headerAction: _addingSection == 'radiology'
                          ? null
                          : IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              onPressed: () => _startAddGeneric('radiology'),
                            ),
                      child: Column(
                        children: [
                          if (_addingSection == 'radiology')
                            AdmissionDetailsGenericAddForm(
                              title: 'Add Radiology Record',
                              saving: _savingGeneric,
                              onCancel: _cancelAddGeneric,
                              onSave: _saveGenericAdd,
                              fields: [
                                AdmissionDetailsFormFieldSpec(
                                  hint: 'Title (e.g. Chest X-Ray)',
                                  controller: _getCtrl('title'),
                                  isRequired: true,
                                ),
                                AdmissionDetailsFormFieldSpec(
                                  hint: 'Report text',
                                  controller: _getCtrl('report'),
                                  maxLines: 3,
                                ),
                              ],
                              childrenAfterFields: [
                                const Text(
                                  'Images or video',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed:
                                          _savingGeneric ? null : _pickRadiologyImages,
                                      icon: const Icon(
                                        Icons.photo_library_outlined,
                                        size: 20,
                                        color: AppColors.primary,
                                      ),
                                      label: const Text('Photos'),
                                    ),
                                    TextButton.icon(
                                      onPressed:
                                          _savingGeneric ? null : _pickRadiologyVideo,
                                      icon: const Icon(
                                        Icons.video_library_outlined,
                                        size: 20,
                                        color: AppColors.primary,
                                      ),
                                      label: const Text('Video'),
                                    ),
                                  ],
                                ),
                                if (_radiologyLocalPaths.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _radiologyLocalPaths.map((path) {
                                        final name =
                                            path.split(Platform.pathSeparator).last;
                                        return InputChip(
                                          label: Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          onDeleted: _savingGeneric
                                              ? null
                                              : () => setState(
                                                    () =>
                                                        _radiologyLocalPaths.remove(path),
                                                  ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                              ],
                            ),
                          if (admission.radiologyImages.isEmpty &&
                              _addingSection != 'radiology')
                            const AdmissionDetailsEmptyHint(
                              'No radiology images recorded.',
                            )
                          else
                            ...admission.radiologyImages.map(
                              (img) => AdmissionDetailsRadiologyCard(
                                image: img,
                                onDelete: () =>
                                    _deleteItem('radiology_images', img.id),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ── Treatment Plans ──────────────────────────────────────
                    AdmissionDetailsSectionContainer(
                      title: 'Treatment Plans',
                      headerAction: _addingSection == 'plan'
                          ? null
                          : IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              onPressed: () => _startAddGeneric('plan'),
                            ),
                      child: Column(
                        children: [
                          if (_addingSection == 'plan')
                            AdmissionDetailsGenericAddForm(
                              title: 'Add Treatment Plan',
                              saving: _savingGeneric,
                              onCancel: _cancelAddGeneric,
                              onSave: _saveGenericAdd,
                              fields: [
                                AdmissionDetailsFormFieldSpec(
                                  hint: 'Plan content',
                                  controller: _getCtrl('plan'),
                                  maxLines: 4,
                                  isRequired: true,
                                ),
                              ],
                            ),
                          if (admission.treatmentPlans.isEmpty &&
                              _addingSection != 'plan')
                            const AdmissionDetailsEmptyHint(
                              'No treatment plans recorded.',
                            )
                          else
                            ...admission.treatmentPlans.map(
                              (p) => AdmissionDetailsTreatmentPlanCard(
                                plan: p,
                                onDelete: () =>
                                    _deleteItem('treatment_plans', p.id),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ── Vital Signs ──────────────────────────────────────────
                    AdmissionDetailsMeasurementSection(
                      title: AppTexts.vitalSigns,
                      isLabs: false,
                      records: admission.vitals,
                      titles: _vitalsTitles,
                      adding: _addingVital,
                      saving: _savingVital,
                      pending: _pendingVital,
                      onStartAdd: _startAddVital,
                      onCancelAdd: _cancelAddVital,
                      onSaveAdd: _saveVital,
                      onPickDate: () => _pickDateTime(
                        initial: _pendingVital?.date,
                        onPick: (d) => setState(() => _pendingVital?.date = d),
                      ),
                    ),

                    // ── Labs ─────────────────────────────────────────────────
                    AdmissionDetailsMeasurementSection(
                      title: AppTexts.labs,
                      isLabs: true,
                      records: admission.labs,
                      titles: _labsTitles,
                      adding: _addingLab,
                      saving: _savingLab,
                      pending: _pendingLab,
                      onStartAdd: _startAddLab,
                      onCancelAdd: _cancelAddLab,
                      onSaveAdd: _saveLab,
                      onPickDate: () => _pickDateTime(
                        initial: _pendingLab?.date,
                        onPick: (d) => setState(() => _pendingLab?.date = d),
                      ),
                    ),

                    // ── Medications ──────────────────────────────────────────
                    AdmissionDetailsSectionContainer(
                      title: 'Medications',
                      headerAction: _addingSection == 'med'
                          ? null
                          : IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              onPressed: () =>
                                  _startAddGeneric('med', defaultType: 'other'),
                            ),
                      child: Column(
                        children: [
                          if (_addingSection == 'med')
                            AdmissionDetailsGenericAddForm(
                              title: 'Add Medication',
                              saving: _savingGeneric,
                              onCancel: _cancelAddGeneric,
                              onSave: _saveGenericAdd,
                              fields: [
                                AdmissionDetailsFormFieldSpec(
                                  hint: 'Title',
                                  controller: _getCtrl('title'),
                                  isRequired: true,
                                ),
                                AdmissionDetailsFormFieldSpec(
                                  hint: 'Value (e.g. 1g IV)',
                                  controller: _getCtrl('value'),
                                ),
                                AdmissionDetailsFormFieldSpec(
                                  hint: 'Duration (e.g. 5 days)',
                                  controller: _getCtrl('duration'),
                                ),
                              ],
                              typeLabel: 'Type',
                              typeValue: _pendingType,
                              types: const [
                                'infusion',
                                'syring_pump',
                                'bolus',
                                'other',
                              ],
                              onTypeChanged: (v) =>
                                  setState(() => _pendingType = v),
                            ),
                          if (admission.medications.isEmpty &&
                              _addingSection != 'med')
                            const AdmissionDetailsEmptyHint(
                              'No medications recorded.',
                            )
                          else
                            ...admission.medications.map(
                              (m) => AdmissionDetailsMedicationCard(
                                med: m,
                                onDelete: () =>
                                    _deleteItem('medications', m.id),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ── Echo ─────────────────────────────────────────────────
                    AdmissionDetailsSectionContainer(
                      title: 'Echo',
                      headerAction: _addingSection == 'echo'
                          ? null
                          : IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              onPressed: () => _startAddGeneric('echo'),
                            ),
                      child: Column(
                        children: [
                          if (_addingSection == 'echo')
                            AdmissionDetailsGenericAddForm(
                              title: 'Add Echo Findings',
                              saving: _savingGeneric,
                              onCancel: _cancelAddGeneric,
                              onSave: _saveGenericAdd,
                              fields: [
                                AdmissionDetailsFormFieldSpec(
                                  hint: 'Note text',
                                  controller: _getCtrl('text'),
                                  maxLines: 3,
                                  isRequired: true,
                                ),
                              ],
                            ),
                          if (admission.echoes.isEmpty &&
                              _addingSection != 'echo')
                            const AdmissionDetailsEmptyHint(
                              'No echo findings recorded.',
                            )
                          else
                            ...admission.echoes.map(
                              (e) => AdmissionDetailsSimpleTextCard(
                                text: e.text,
                                date: e.createdAt,
                                onDelete: () => _deleteItem('echo', e.id),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ── Ultrasound ───────────────────────────────────────────
                    AdmissionDetailsSectionContainer(
                      title: 'Ultrasound',
                      headerAction: _addingSection == 'us'
                          ? null
                          : IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              onPressed: () => _startAddGeneric('us'),
                            ),
                      child: Column(
                        children: [
                          if (_addingSection == 'us')
                            AdmissionDetailsGenericAddForm(
                              title: 'Add Ultrasound Findings',
                              saving: _savingGeneric,
                              onCancel: _cancelAddGeneric,
                              onSave: _saveGenericAdd,
                              fields: [
                                AdmissionDetailsFormFieldSpec(
                                  hint: 'Note text',
                                  controller: _getCtrl('text'),
                                  maxLines: 3,
                                  isRequired: true,
                                ),
                              ],
                            ),
                          if (admission.ultrasounds.isEmpty &&
                              _addingSection != 'us')
                            const AdmissionDetailsEmptyHint(
                              'No ultrasound findings recorded.',
                            )
                          else
                            ...admission.ultrasounds.map(
                              (u) => AdmissionDetailsSimpleTextCard(
                                text: u.text,
                                date: u.createdAt,
                                onDelete: () =>
                                    _deleteItem('ultrasounds', u.id),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ── Cultures ─────────────────────────────────────────────
                    AdmissionDetailsSectionContainer(
                      title: 'Cultures',
                      headerAction: _addingSection == 'culture'
                          ? null
                          : IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              onPressed: () => _startAddGeneric('culture'),
                            ),
                      child: Column(
                        children: [
                          if (_addingSection == 'culture')
                            AdmissionDetailsGenericAddForm(
                              title: 'Add Culture',
                              saving: _savingGeneric,
                              onCancel: _cancelAddGeneric,
                              onSave: _saveGenericAdd,
                              fields: [
                                AdmissionDetailsFormFieldSpec(
                                  hint: 'Title',
                                  controller: _getCtrl('title'),
                                  isRequired: true,
                                ),
                                AdmissionDetailsFormFieldSpec(
                                  hint: 'Note',
                                  controller: _getCtrl('note'),
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          if (admission.cultures.isEmpty &&
                              _addingSection != 'culture')
                            const AdmissionDetailsEmptyHint(
                              'No cultures recorded.',
                            )
                          else
                            ...admission.cultures.map(
                              (c) => AdmissionDetailsCultureCard(
                                culture: c,
                                onDelete: () => _deleteItem('cultures', c.id),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ── Doctor info ──────────────────────────────────────────
                    if (admission.doctor != null)
                      AdmissionDetailsSectionContainer(
                        title: 'Doctor',
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 6,
                          children: [
                            AdmissionDetailsMetaChip(
                              label: 'Name',
                              value: admission.doctor!.name,
                              icon: Icons.person_outline,
                            ),
                            AdmissionDetailsMetaChip(
                              label: 'Email',
                              value: admission.doctor!.email,
                              icon: Icons.email_outlined,
                            ),
                            AdmissionDetailsMetaChip(
                              label: 'Phone',
                              value: admission.doctor!.phone.isEmpty
                                  ? AppTexts.notAvailable
                                  : admission.doctor!.phone,
                              icon: Icons.phone_outlined,
                            ),
                          ],
                        ),
                      ),

                    // ── Hospital Group ───────────────────────────────────────
                    if (admission.hospitalGroup != null)
                      AdmissionDetailsSectionContainer(
                        title: 'Ward / Group',
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 6,
                          children: [
                            AdmissionDetailsMetaChip(
                              label: 'Name',
                              value: admission.hospitalGroup!.name,
                              icon: Icons.business,
                            ),
                            AdmissionDetailsMetaChip(
                              label: 'Total beds',
                              value: '${admission.hospitalGroup!.totalBeds}',
                              icon: Icons.bed_outlined,
                            ),
                            AdmissionDetailsMetaChip(
                              label: 'Available beds',
                              value:
                                  '${admission.hospitalGroup!.availableBeds}',
                              icon: Icons.event_available,
                            ),
                          ],
                        ),
                      ),

                    // ── Admission Notes ──────────────────────────────────────
                    AdmissionDetailsSectionContainer(
                      title: AppTexts.admissionNotesSection,
                      child: Text(
                        admission.notes.isEmpty
                            ? AppTexts.notAvailable
                            : admission.notes,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
