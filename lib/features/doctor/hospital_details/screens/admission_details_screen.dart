import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/core/widgets/app_button.dart';

import '../../../superAdmin/patients/models/admission_request_model.dart';
import '../../../superAdmin/patients/models/patient_admission_models.dart';
import '../data/default_patient_lab_titles.dart';
import '../enums/admission_status.dart';
import '../utils/admission_update_validation.dart';
import '../repository/hospital_admissions_repository.dart';
import '../services/admission_pdf_builder.dart';
import 'admission_activity_history_screen.dart';
import '../widgets/admission_exit_outcome_sheet.dart';
import '../widgets/add_patient_measurement_title_sheet.dart';
import '../widgets/admission_details_clinical_notes_section.dart';
import '../widgets/admission_details_consultation_card.dart';
import '../widgets/admission_details_culture_card.dart';
import '../widgets/admission_details_empty_hint.dart';
import '../widgets/admission_details_formatters.dart';
import '../widgets/admission_details_generic_add_form.dart';
import '../widgets/admission_details_info_section.dart';
import '../widgets/admission_details_medication_card.dart';
import '../widgets/admission_details_measurement_section.dart';
import '../widgets/admission_details_meta_chip.dart';
import '../widgets/admission_details_patient_header_section.dart';
import '../widgets/admission_details_radiology_card.dart';
import '../widgets/admission_details_section_container.dart';
import '../widgets/admission_details_simple_text_card.dart';
import '../widgets/admission_plans_section.dart';
import '../widgets/pending_measurement_column_entry.dart';

class AdmissionDetailsScreen extends StatefulWidget {
  const AdmissionDetailsScreen({super.key, required this.admissionId});
  final int admissionId;

  @override
  State<AdmissionDetailsScreen> createState() => _AdmissionDetailsScreenState();
}

class _AdmissionDetailsScreenState extends State<AdmissionDetailsScreen> {
  PatientAdmissionModel? _admission;
  bool _loadingAdmission = true;
  Object? _admissionError;
  final _repo = const HospitalAdmissionsRepository();
  bool _exportingPdf = false;
  bool _exitingAdmission = false;


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
  bool _addingVitalTitle = false;
  PendingMeasurementColumnEntry? _pendingVital;
  List<MeasurementTitleModel> _vitalsTitles = [];


  bool _addingLab = false;
  bool _savingLab = false;
  bool _addingLabTitle = false;
  PendingMeasurementColumnEntry? _pendingLab;
  List<MeasurementTitleModel> _labsTitles = [];


  String? _addingSection;
  bool _savingGeneric = false;
  String? _editingSection;
  int? _editingItemId;
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
    _fetchAdmission(silent: false);
  }

  @override
  void dispose() {
    _disposePatientCtrls();
    _disposeAdmissionCtrls();
    _disposePendingVitalColumn();
    _disposePendingLabColumn();
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

  Future<void> _fetchAdmission({required bool silent}) async {
    if (!silent) {
      setState(() {
        _loadingAdmission = _admission == null;
        _admissionError = null;
      });
    }

    try {
      final data = await _repo.getAdmission(widget.admissionId);
      if (!mounted) return;
      setState(() {
        _admission = data;
        _loadingAdmission = false;
        _admissionError = null;
      });
      _loadTitles(data.patientId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingAdmission = false;
        if (_admission == null) _admissionError = e;
      });
    }
  }

  void _loadAdmission() {
    _fetchAdmission(silent: false);
  }

  Future<void> _silentRefreshAdmission() async {
    await _fetchAdmission(silent: true);
  }

  void _openActivityHistory() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AdmissionActivityHistoryScreen(
          admissionId: widget.admissionId,
        ),
      ),
    );
  }

  Future<void> _refreshAdmission() async {
    if (_editingPatient) _cancelPatientEdit();
    if (_editingAdmission) _cancelAdmissionEdit();
    _cancelEditGeneric();
    _cancelAddGeneric();
    _cancelAddVitalColumn();
    _cancelAddLabColumn();
    await _silentRefreshAdmission();
  }

  Future<void> _exportAdmissionPdf(PatientAdmissionModel admission) async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);

    try {
      final bytes = await AdmissionPdfBuilder.build(admission: admission);

      // Keep letters from any script (Arabic included) + digits, collapse
      // whitespace to underscores so the shared file keeps the patient name.
      final patientName = admission.patient?.name.trim();
      final rawSlug = (patientName != null && patientName.isNotEmpty)
          ? patientName
              .replaceAll(RegExp(r'[^\p{L}\p{N}\s-]', unicode: true), '')
              .trim()
              .replaceAll(RegExp(r'\s+'), '_')
          : 'admission';
      final slug = rawSlug.isEmpty ? 'admission' : rawSlug;
      final fileName = '${slug}_${admission.id}.pdf';

      if (!mounted) return;
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppTexts.admissionPdfExportFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Future<void> _loadTitles(int patientId) async {
    try {
      final v = await _repo.listPatientVitalsTitles(patientId);
      final l = await _repo.listPatientLabsTitles(patientId);
      if (mounted) {
        setState(() {
          _vitalsTitles = v;
          _labsTitles = l;
        });
      }
    } catch (_) {}
  }

  Future<void> _addPatientVitalTitle(int patientId) async {
    final values = await AddPatientMeasurementTitleSheet.show(
      context,
      isLabs: false,
    );
    if (values == null || !mounted) return;

    setState(() => _addingVitalTitle = true);
    try {
      final created = await _repo.createPatientVitalTitle(
        patientId: patientId,
        title: values.title,
        unit: values.unit,
        valueType: values.valueType,
        normalRangeMin: values.normalRangeMin,
        normalRangeMax: values.normalRangeMax,
      );
      if (!mounted) return;
      setState(() {
        _vitalsTitles = [..._vitalsTitles, created];
        _pendingVital?.controllers.putIfAbsent(
          created.id,
          () => TextEditingController(),
        );
      });
      _showSnack(AppTexts.vitalTitleCreated);
    } on NetworkException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _addingVitalTitle = false);
    }
  }

  Future<void> _addPatientLabTitle(int patientId) async {
    final values = await AddPatientMeasurementTitleSheet.show(
      context,
      isLabs: true,
    );
    if (values == null || !mounted) return;

    setState(() => _addingLabTitle = true);
    try {
      final created = await _repo.createPatientLabTitle(
        patientId: patientId,
        title: values.title,
        unit: values.unit,
        normalRangeMin: values.normalRangeMin,
        normalRangeMax: values.normalRangeMax,
      );
      if (!mounted) return;
      setState(() {
        _labsTitles = [..._labsTitles, created];
        _pendingLab?.controllers.putIfAbsent(
          created.id,
          () => TextEditingController(),
        );
      });
      _showSnack(AppTexts.labTitleCreated);
    } on NetworkException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _addingLabTitle = false);
    }
  }

  Future<void> _ensureDefaultLabTitles(int patientId) async {
    for (final preset in DefaultPatientLabTitles.presets) {
      final exists = _labsTitles.any(
        (title) =>
            title.title.trim().toLowerCase() == preset.title.trim().toLowerCase(),
      );
      if (exists) continue;

      try {
        final created = await _repo.createPatientLabTitle(
          patientId: patientId,
          title: preset.title,
          unit: preset.unit,
          valueType: preset.valueType,
          normalRangeMin: preset.normalRangeMin,
          normalRangeMax: preset.normalRangeMax,
        );
        if (!mounted) return;
        setState(() => _labsTitles = [..._labsTitles, created]);
      } on NetworkException catch (e) {
        if (!mounted) return;
        _showSnack(e.message, isError: true);
      }
    }
  }

  
  void _startAddGeneric(String section, {String? defaultType}) {
    _cancelEditGeneric();
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

  void _cancelEditGeneric() {
    setState(() {
      _editingSection = null;
      _editingItemId = null;
    });
  }

  void _beginEditItem(
    String section,
    int itemId, {
    String? type,
    Map<String, String> fields = const {},
  }) {
    _cancelAddGeneric();
    _cancelEditGeneric();
    _cancelAddVitalColumn();
    _cancelAddLabColumn();
    for (final c in _genericCtrls.values) {
      c.dispose();
    }
    _genericCtrls.clear();
    _radiologyLocalPaths.clear();
    _pendingType = section == 'clinical_note' && type != null
        ? AdmissionClinicalNoteType.normalize(type)
        : type;
    for (final entry in fields.entries) {
      _getCtrl(entry.key).text = entry.value;
    }
    setState(() {
      _editingSection = section;
      _editingItemId = itemId;
    });
  }

  String? _validateGenericSection(String section) {
    switch (section) {
      case 'med':
        return AdmissionUpdateValidation.medicationFields(
          title: _getCtrl('title').text,
          type: _pendingType,
        );
      case 'clinical_note':
        final contentError = AdmissionUpdateValidation.clinicalNoteContent(
          _getCtrl('content').text,
        );
        if (contentError != null) return contentError;
        if (!AdmissionClinicalNoteType.values.contains(_pendingType)) {
          return 'Select a valid note type';
        }
        return null;
      case 'radiology':
        return AdmissionUpdateValidation.radiologyTitle(_getCtrl('title').text);
      case 'plan':
        return AdmissionUpdateValidation.treatmentPlanContent(
          _getCtrl('plan').text,
        );
      case 'echo':
      case 'us':
        return AdmissionUpdateValidation.requiredText(
          _getCtrl('text').text,
          field: 'Note text',
        );
      case 'culture':
        return AdmissionUpdateValidation.requiredText(
          _getCtrl('title').text,
          field: 'Culture title',
        );
      case 'consultation':
        return AdmissionUpdateValidation.requiredText(
          _getCtrl('speciality').text,
          field: 'Speciality',
        );
      default:
        return null;
    }
  }

  Future<void> _saveGenericEdit() async {
    if (_editingSection == null || _editingItemId == null) return;
    final section = _editingSection!;
    final validationError = _validateGenericSection(section);
    if (validationError != null) {
      _showSnack(validationError, isError: true);
      return;
    }

    setState(() => _savingGeneric = true);
    try {
      final id = _editingItemId!;
      final body = <String, dynamic>{};
      final item = <String, dynamic>{'id': id};

      if (section == 'med') {
        item['type'] = _pendingType ?? 'other';
        item['title'] = _getCtrl('title').text.trim();
        item['value'] = _getCtrl('value').text.trim();
        item['duration'] = _getCtrl('duration').text.trim();
        body['medications'] = [item];
      } else if (section == 'clinical_note') {
        item['type'] = AdmissionClinicalNoteType.normalize(_pendingType);
        item['content'] = _getCtrl('content').text.trim();
        body['clinical_notes'] = [item];
      } else if (section == 'radiology') {
        final title = _getCtrl('title').text.trim();
        final report = _getCtrl('report').text.trim();
        item['title'] = title;
        if (report.isNotEmpty) item['report'] = report;
        body['radiology_images'] = [item];
      } else if (section == 'echo') {
        item['text'] = _getCtrl('text').text.trim();
        body['echoes'] = [item];
      } else if (section == 'us') {
        item['text'] = _getCtrl('text').text.trim();
        body['ultrasounds'] = [item];
      } else if (section == 'culture') {
        item['title'] = _getCtrl('title').text.trim();
        item['note'] = _getCtrl('note').text.trim();
        body['cultures'] = [item];
      } else if (section == 'consultation') {
        item['speciality'] = _getCtrl('speciality').text.trim();
        item['reply'] = _getCtrl('reply').text.trim();
        body['consultations'] = [item];
      } else if (section == 'plan') {
        item['plan_content'] = _getCtrl('plan').text.trim();
        body['treatment_plans'] = [item];
      }

      await _repo.updateAdmissionRaw(widget.admissionId, body);
      if (!mounted) return;
      _showSnack(AppTexts.entryUpdated);
      _cancelEditGeneric();
      for (final c in _genericCtrls.values) {
        c.dispose();
      }
      _genericCtrls.clear();
      _silentRefreshAdmission();
    } on NetworkException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _savingGeneric = false);
    }
  }

  Widget _buildGenericEditForm({
    required String section,
    required String title,
    required List<AdmissionDetailsFormFieldSpec> fields,
    List<String>? types,
    String? typeLabel,
    List<Widget> childrenAfterFields = const [],
  }) {
    return AdmissionDetailsGenericAddForm(
      title: title,
      isEditing: true,
      saving: _savingGeneric,
      onCancel: () {
        _cancelEditGeneric();
        for (final c in _genericCtrls.values) {
          c.dispose();
        }
        _genericCtrls.clear();
        setState(() {});
      },
      onSave: _saveGenericEdit,
      typeLabel: typeLabel,
      typeValue: _pendingType,
      types: types,
      onTypeChanged: types == null
          ? null
          : (v) => setState(() => _pendingType = v),
      fields: fields,
      childrenAfterFields: childrenAfterFields,
    );
  }

  bool _isEditingItem(String section, int id) =>
      _editingSection == section && _editingItemId == id;

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
    final section = _addingSection!;
    final validationError = _validateGenericSection(section);
    if (validationError != null) {
      _showSnack(validationError, isError: true);
      return;
    }

    setState(() => _savingGeneric = true);
    try {
      final body = <String, dynamic>{};

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
            'type': AdmissionClinicalNoteType.normalize(_pendingType),
            'content': _getCtrl('content').text.trim(),
          },
        ];
      } else if (section == 'radiology') {
        final title = _getCtrl('title').text.trim();
        final report = _getCtrl('report').text.trim();
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
          if (!mounted) return;
          _showSnack('Entry added');
          _cancelAddGeneric();
          _silentRefreshAdmission();
          return;
        }
        body['radiology_images'] = [
          {
            'title': title,
            if (report.isNotEmpty) 'report': report,
          },
        ];
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
      } else if (section == 'consultation') {
        body['consultations'] = [
          {
            'speciality': _getCtrl('speciality').text.trim(),
            'reply': _getCtrl('reply').text.trim(),
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
      _silentRefreshAdmission();
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
      _silentRefreshAdmission();
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
      _silentRefreshAdmission();
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
    _editStatus = AdmissionStatus.fromApiValue(a.status);
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

    final dateError = AdmissionUpdateValidation.admissionStatusDates(
      status: _editStatus,
      dateComes: _editDateComes,
      dateLeave: _editDateLeave,
      dateOfDeath: _editDateOfDeath,
    );
    if (dateError != null) {
      _showSnack(dateError, isError: true);
      return;
    }

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
      _silentRefreshAdmission();
    } on NetworkException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _savingAdmission = false);
    }
  }

  void _disposePendingVitalColumn() {
    _pendingVital?.dispose();
    _pendingVital = null;
  }

  void _disposePendingLabColumn() {
    _pendingLab?.dispose();
    _pendingLab = null;
  }

  String _vitalColumnKey(VitalRecordModel record) =>
      record.date.isNotEmpty ? record.date : record.createdAt;

  String _labColumnKey(LabRecordModel record) =>
      record.date.isNotEmpty ? record.date : record.createdAt;

  void _startAddVitalColumn() {
    _cancelEditGeneric();
    _cancelAddLabColumn();
    _disposePendingVitalColumn();
    _pendingVital = PendingMeasurementColumnEntry(titles: _vitalsTitles);
    setState(() => _addingVital = true);
  }

  void _cancelAddVitalColumn() {
    _disposePendingVitalColumn();
    setState(() => _addingVital = false);
  }

  void _editVitalColumn(String columnKey) {
    final records = _admission?.vitals ?? const <VitalRecordModel>[];
    _cancelEditGeneric();
    _cancelAddLabColumn();
    _disposePendingVitalColumn();

    final recordIds = <int, int>{};
    final values = <int, String>{};
    DateTime? columnDate;

    for (final record in records) {
      if (_vitalColumnKey(record) != columnKey) continue;
      recordIds[record.vitalsTitleId] = record.id;
      values[record.vitalsTitleId] = record.value;
      columnDate ??= DateTime.tryParse(record.date) ??
          DateTime.tryParse(record.createdAt);
    }

    _pendingVital = PendingMeasurementColumnEntry(
      titles: _vitalsTitles,
      date: columnDate ?? DateTime.now(),
      recordIdsByTitleId: recordIds,
      initialValuesByTitleId: values,
      editingColumnKey: columnKey,
    );
    setState(() => _addingVital = true);
  }

  Future<void> _saveVitalColumn() async {
    final pending = _pendingVital;
    if (pending == null) return;

    final items = <Map<String, dynamic>>[];
    for (final title in _vitalsTitles) {
      final text = pending.controllers[title.id]?.text.trim() ?? '';
      if (text.isEmpty) continue;
      final valueError = AdmissionUpdateValidation.measurementValue(
        raw: text,
        field: title.title,
        isNumeric: title.isNumericValueType,
      );
      if (valueError != null) {
        _showSnack(valueError, isError: true);
        return;
      }
      final parsedValue = title.isNumericValueType
          ? (double.tryParse(text) ?? 0)
          : text;
      items.add({
        if (pending.recordIdsByTitleId[title.id] != null)
          'id': pending.recordIdsByTitleId[title.id],
        'vitals_title_id': title.id,
        'value': parsedValue,
        'date': admissionDetailsSqlDateTime(pending.date),
      });
    }

    if (items.isEmpty) {
      _showSnack('Enter at least one value', isError: true);
      return;
    }

    setState(() => _savingVital = true);
    try {
      await _repo.updateAdmissionRaw(widget.admissionId, {'vitals': items});
      if (!mounted) return;
      _showSnack(
        pending.isEditingExisting ? AppTexts.entryUpdated : 'Vitals added',
      );
      _cancelAddVitalColumn();
      _silentRefreshAdmission();
    } on NetworkException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _savingVital = false);
    }
  }

  Future<void> _startAddLabColumn(int patientId) async {
    _cancelEditGeneric();
    _cancelAddVitalColumn();
    _disposePendingLabColumn();

    await _ensureDefaultLabTitles(patientId);
    if (!mounted) return;

    _pendingLab = PendingMeasurementColumnEntry(titles: _labsTitles);
    setState(() => _addingLab = true);
  }

  void _cancelAddLabColumn() {
    _disposePendingLabColumn();
    setState(() => _addingLab = false);
  }

  void _editLabColumn(String columnKey) {
    final records = _admission?.labs ?? const <LabRecordModel>[];
    _cancelEditGeneric();
    _cancelAddVitalColumn();
    _disposePendingLabColumn();

    final recordIds = <int, int>{};
    final values = <int, String>{};
    DateTime? columnDate;

    for (final record in records) {
      if (_labColumnKey(record) != columnKey) continue;
      recordIds[record.labsTitleId] = record.id;
      values[record.labsTitleId] = record.value;
      columnDate ??= DateTime.tryParse(record.date) ??
          DateTime.tryParse(record.createdAt);
    }

    _pendingLab = PendingMeasurementColumnEntry(
      titles: _labsTitles,
      date: columnDate ?? DateTime.now(),
      recordIdsByTitleId: recordIds,
      initialValuesByTitleId: values,
      editingColumnKey: columnKey,
    );
    setState(() => _addingLab = true);
  }

  Future<void> _saveLabColumn() async {
    final pending = _pendingLab;
    if (pending == null) return;

    final items = <Map<String, dynamic>>[];
    for (final title in _labsTitles) {
      final text = pending.controllers[title.id]?.text.trim() ?? '';
      if (text.isEmpty) continue;
      final valueError = AdmissionUpdateValidation.numericValue(
        text,
        field: title.title,
      );
      if (valueError != null) {
        _showSnack(valueError, isError: true);
        return;
      }
      items.add({
        if (pending.recordIdsByTitleId[title.id] != null)
          'id': pending.recordIdsByTitleId[title.id],
        'labs_title_id': title.id,
        'value': double.tryParse(text) ?? 0,
        'date': admissionDetailsSqlDateTime(pending.date),
      });
    }

    if (items.isEmpty) {
      _showSnack('Enter at least one value', isError: true);
      return;
    }

    setState(() => _savingLab = true);
    try {
      await _repo.updateAdmissionRaw(widget.admissionId, {'labs': items});
      if (!mounted) return;
      _showSnack(
        pending.isEditingExisting ? AppTexts.entryUpdated : 'Lab results added',
      );
      _cancelAddLabColumn();
      _silentRefreshAdmission();
    } on NetworkException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _savingLab = false);
    }
  }

  Future<DateTime?> _pickDateTimeValue({DateTime? initial}) async {
    final base = initial ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: DateTime(base.year, base.month, base.day),
    );
    if (d == null || !mounted) return null;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (t == null || !mounted) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  Future<void> _pickDateTime({
    required DateTime? initial,
    required void Function(DateTime) onPick,
  }) async {
    final picked = await _pickDateTimeValue(initial: initial);
    if (picked != null) onPick(picked);
  }

  Future<void> _exitAdmission(PatientAdmissionModel admission) async {
    if (_exitingAdmission) return;
    if (AdmissionStatus.isDischargedOutcome(admission.status)) {
      _showSnack('This admission is already closed.', isError: true);
      return;
    }

    final status = await AdmissionExitOutcomeSheet.show(context);
    if (status == null || !mounted) return;

    DateTime? dateLeave;
    DateTime? dateOfDeath;

    if (status.requiresLeaveDate) {
      dateLeave = await _pickDateTimeValue(initial: DateTime.now());
      if (dateLeave == null || !mounted) return;
    } else if (status.requiresDeathDate) {
      dateOfDeath = await _pickDateTimeValue(initial: DateTime.now());
      if (dateOfDeath == null || !mounted) return;
    }

    final dateComes = admission.dateComes != null
        ? DateTime.tryParse(admission.dateComes!)
        : null;
    final dateError = AdmissionUpdateValidation.admissionStatusDates(
      status: status,
      dateComes: dateComes,
      dateLeave: dateLeave,
      dateOfDeath: dateOfDeath,
    );
    if (dateError != null) {
      _showSnack(dateError, isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm exit'),
        content: Text(
          'Mark this patient as ${status.dischargedScreenLabel}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              status.dischargedScreenLabel,
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _exitingAdmission = true);
    try {
      await _repo.updateAdmissionRaw(admission.id, {
        'status': status.apiValue,
        if (dateLeave != null)
          'date_leave': admissionDetailsSqlDateTime(dateLeave),
        if (dateOfDeath != null)
          'date_of_death': admissionDetailsSqlDateTime(dateOfDeath),
      });
      if (!mounted) return;
      _showSnack('Patient marked as ${status.dischargedScreenLabel}');
      Navigator.pop(context, true);
    } on NetworkException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to update admission: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exitingAdmission = false);
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

  @override
  Widget build(BuildContext context) {
    final admission = _admission;
    final patientName = admission?.patient?.name.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          patientName != null && patientName.isNotEmpty
              ? patientName
              : AppTexts.admissionsSection,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (admission != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: AppTexts.exportAdmissionPdf,
                  onPressed: _exportingPdf
                      ? null
                      : () => _exportAdmissionPdf(admission),
                  icon: _exportingPdf
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(
                          Icons.picture_as_pdf_outlined,
                          color: AppColors.primary,
                        ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textPrimary,
                  ),
                  onSelected: (val) {
                    if (val == 'activity_history') {
                      _openActivityHistory();
                    } else if (val == 'export_pdf') {
                      _exportAdmissionPdf(admission);
                    } else if (val == 'edit_patient') {
                      final p = admission.patient;
                      if (p != null) _beginPatientEdit(p);
                    } else if (val == 'edit_admission') {
                      _beginAdmissionEdit(admission);
                    } else if (val == 'exit') {
                      _exitAdmission(admission);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'activity_history',
                      child: Text(AppTexts.activityHistorySection),
                    ),
                    PopupMenuItem(
                      value: 'export_pdf',
                      enabled: !_exportingPdf,
                      child: Text(AppTexts.exportAdmissionPdf),
                    ),
                    if (admission.patient != null)
                      PopupMenuItem(
                        value: 'edit_patient',
                        child: Text(AppTexts.editPatientAdmin),
                      ),
                    PopupMenuItem(
                      value: 'edit_admission',
                      child: Text(AppTexts.editAdmission),
                    ),
                    if (!AdmissionStatus.isDischargedOutcome(admission.status))
                      PopupMenuItem(
                        value: 'exit',
                        enabled: !_exitingAdmission,
                        child: Text(
                          _exitingAdmission ? 'Exiting…' : 'Exit',
                        ),
                      ),
                  ],
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(admission),
      ),
    );
  }

  Widget _buildBody(PatientAdmissionModel? admission) {
    if (_loadingAdmission && admission == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_admissionError != null && admission == null) {
      final msg = _admissionError is NetworkException
          ? (_admissionError as NetworkException).message
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

    if (admission == null) return const SizedBox.shrink();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refreshAdmission,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildAdmissionSections(admission),
        ),
      ),
    );
  }

  List<Widget> _buildAdmissionSections(PatientAdmissionModel admission) {
    return [
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
                    //
                    // AdmissionDetailsInfoSection(
                    //   admission: admission,
                    //   editing: _editingAdmission,
                    //   saving: _savingAdmission,
                    //   formKey: _admissionEditFormKey,
                    //   bedCtrl: _bedCtrl,
                    //   notesCtrl: _admissionNotesCtrl,
                    //   editStatus: _editStatus,
                    //   editDateComes: _editDateComes,
                    //   editDateLeave: _editDateLeave,
                    //   editDateOfDeath: _editDateOfDeath,
                    //   onStatusChanged: (v) => setState(
                    //     () => _editStatus = v ?? AdmissionStatus.admitted,
                    //   ),
                    //   onPickDateLeave: () => _pickDateTime(
                    //     initial: _editDateLeave,
                    //     onPick: (d) => setState(() => _editDateLeave = d),
                    //   ),
                    //   onClearDateLeave: () =>
                    //       setState(() => _editDateLeave = null),
                    //   onPickDateOfDeath: () => _pickDateTime(
                    //     initial: _editDateOfDeath,
                    //     onPick: (d) => setState(() => _editDateOfDeath = d),
                    //   ),
                    //   onClearDateOfDeath: () =>
                    //       setState(() => _editDateOfDeath = null),
                    //   onBeginEdit: () => _beginAdmissionEdit(admission),
                    //   onCancel: _cancelAdmissionEdit,
                    //   onSave: () => _saveAdmissionEdit(admission),
                    // ),
                    // const SizedBox(height: 8),

                    // ── History and complaint ────────────────────────────────
                    AdmissionDetailsClinicalNotesSection(
                      notes: admission.clinicalNotes,
                      adding: _addingSection == 'clinical_note',
                      editingItemId: _editingSection == 'clinical_note'
                          ? _editingItemId
                          : null,
                      pendingType: _pendingType,
                      saving: _savingGeneric,
                      contentController: _getCtrl('content'),
                      onStartAdd: (type) => _startAddGeneric(
                        'clinical_note',
                        defaultType: type,
                      ),
                      onCancelAdd: () {
                        _cancelAddGeneric();
                        for (final c in _genericCtrls.values) {
                          c.dispose();
                        }
                        _genericCtrls.clear();
                        setState(() {});
                      },
                      onSaveAdd: _saveGenericAdd,
                      onBeginEdit: (note) => _beginEditItem(
                        'clinical_note',
                        note.id,
                        type: note.type,
                        fields: {'content': note.content},
                      ),
                      onCancelEdit: () {
                        _cancelEditGeneric();
                        for (final c in _genericCtrls.values) {
                          c.dispose();
                        }
                        _genericCtrls.clear();
                        setState(() {});
                      },
                      onSaveEdit: _saveGenericEdit,
                      onDelete: (id) => _deleteItem('clinical_notes', id),
                    ),

                    // ── Radiology ────────────────────────────────────────────
                    AdmissionDetailsSectionContainer(
                      title: 'Radiology',
                      headerAction: _addingSection == 'radiology' ||
                              _editingSection == 'radiology'
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
                          else ...[
                            ...admission.radiologyImages
                                .where((img) => _isEditingItem('radiology', img.id))
                                .map(
                              (img) => _buildGenericEditForm(
                                section: 'radiology',
                                title: 'Edit Radiology Record',
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
                              ),
                            ),
                            if (admission.radiologyImages.any(
                              (img) => !_isEditingItem('radiology', img.id),
                            ))
                              SizedBox(
                                height: 280,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: admission.radiologyImages
                                      .where(
                                        (img) =>
                                            !_isEditingItem('radiology', img.id),
                                      )
                                      .length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 0),
                                  itemBuilder: (context, index) {
                                    final img = admission.radiologyImages
                                        .where(
                                          (img) => !_isEditingItem(
                                            'radiology',
                                            img.id,
                                          ),
                                        )
                                        .elementAt(index);
                                    return AdmissionDetailsRadiologyCard(
                                      image: img,
                                      compact: true,
                                      onEdit: () => _beginEditItem(
                                        'radiology',
                                        img.id,
                                        fields: {
                                          'title': img.title,
                                          'report': img.report,
                                        },
                                      ),
                                      onDelete: () => _deleteItem(
                                        'radiology_images',
                                        img.id,
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),

                    // ── Plans ────────────────────────────────────────────────
                    AdmissionPlansSection(
                      plans: admission.treatmentPlans,
                      adding: _addingSection == 'plan',
                      editingItemId:
                          _editingSection == 'plan' ? _editingItemId : null,
                      saving: _savingGeneric,
                      contentController: _getCtrl('plan'),
                      onStartAdd: () => _startAddGeneric('plan'),
                      onCancelAdd: () {
                        _cancelAddGeneric();
                        for (final c in _genericCtrls.values) {
                          c.dispose();
                        }
                        _genericCtrls.clear();
                        setState(() {});
                      },
                      onSaveAdd: _saveGenericAdd,
                      onBeginEdit: (plan) => _beginEditItem(
                        'plan',
                        plan.id,
                        fields: {'plan': plan.planContent},
                      ),
                      onCancelEdit: () {
                        _cancelEditGeneric();
                        for (final c in _genericCtrls.values) {
                          c.dispose();
                        }
                        _genericCtrls.clear();
                        setState(() {});
                      },
                      onSaveEdit: _saveGenericEdit,
                      onDelete: (id) => _deleteItem('treatment_plans', id),
                    ),

                    // ── Vital Signs ──────────────────────────────────────────
                    AdmissionDetailsMeasurementSection(
                      title: AppTexts.vitalSigns,
                      isLabs: false,
                      records: admission.vitals,
                      titles: _vitalsTitles,
                      addingColumn: _addingVital,
                      saving: _savingVital,
                      pendingColumn: _pendingVital,
                      addingTitle: _addingVitalTitle,
                      onStartAddColumn: _startAddVitalColumn,
                      onCancelAddColumn: _cancelAddVitalColumn,
                      onSaveColumn: _saveVitalColumn,
                      onEditColumn: _editVitalColumn,
                      onAddTitle: () => _addPatientVitalTitle(admission.patientId),
                      onPickColumnDate: () => _pickDateTime(
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
                      addingColumn: _addingLab,
                      saving: _savingLab,
                      pendingColumn: _pendingLab,
                      addingTitle: _addingLabTitle,
                      onStartAddColumn: () => _startAddLabColumn(admission.patientId),
                      onCancelAddColumn: _cancelAddLabColumn,
                      onSaveColumn: _saveLabColumn,
                      onEditColumn: _editLabColumn,
                      onAddTitle: () => _addPatientLabTitle(admission.patientId),
                      onPickColumnDate: () => _pickDateTime(
                        initial: _pendingLab?.date,
                        onPick: (d) => setState(() => _pendingLab?.date = d),
                      ),
                    ),

                    AdmissionDetailsSectionContainer(
                      title: 'Medications',
                      headerAction: _addingSection == 'med' ||
                              _editingSection == 'med'
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
                              (m) {
                                if (_isEditingItem('med', m.id)) {
                                  return _buildGenericEditForm(
                                    section: 'med',
                                    title: 'Edit Medication',
                                    typeLabel: 'Type',
                                    types: const [
                                      'infusion',
                                      'syring_pump',
                                      'bolus',
                                      'other',
                                    ],
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
                                  );
                                }
                                return AdmissionDetailsMedicationCard(
                                  med: m,
                                  onEdit: () => _beginEditItem(
                                    'med',
                                    m.id,
                                    type: m.type,
                                    fields: {
                                      'title': m.title,
                                      'value': m.value,
                                      'duration': m.duration,
                                    },
                                  ),
                                  onDelete: () =>
                                      _deleteItem('medications', m.id),
                                );
                              },
                            ),
                        ],
                      ),
                    ),

                    AdmissionDetailsSectionContainer(
                      title: 'Echo',
                      headerAction: _addingSection == 'echo' ||
                              _editingSection == 'echo'
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
                              (e) {
                                if (_isEditingItem('echo', e.id)) {
                                  return _buildGenericEditForm(
                                    section: 'echo',
                                    title: 'Edit Echo Findings',
                                    fields: [
                                      AdmissionDetailsFormFieldSpec(
                                        hint: 'Note text',
                                        controller: _getCtrl('text'),
                                        maxLines: 3,
                                        isRequired: true,
                                      ),
                                    ],
                                  );
                                }
                                return AdmissionDetailsSimpleTextCard(
                                  text: e.text,
                                  date: e.createdAt,
                                  onEdit: () => _beginEditItem(
                                    'echo',
                                    e.id,
                                    fields: {'text': e.text},
                                  ),
                                  onDelete: () => _deleteItem('echo', e.id),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    AdmissionDetailsSectionContainer(
                      title: 'Ultrasound',
                      headerAction: _addingSection == 'us' ||
                              _editingSection == 'us'
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
                              (u) {
                                if (_isEditingItem('us', u.id)) {
                                  return _buildGenericEditForm(
                                    section: 'us',
                                    title: 'Edit Ultrasound Findings',
                                    fields: [
                                      AdmissionDetailsFormFieldSpec(
                                        hint: 'Note text',
                                        controller: _getCtrl('text'),
                                        maxLines: 3,
                                        isRequired: true,
                                      ),
                                    ],
                                  );
                                }
                                return AdmissionDetailsSimpleTextCard(
                                  text: u.text,
                                  date: u.createdAt,
                                  onEdit: () => _beginEditItem(
                                    'us',
                                    u.id,
                                    fields: {'text': u.text},
                                  ),
                                  onDelete: () =>
                                      _deleteItem('ultrasounds', u.id),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    AdmissionDetailsSectionContainer(
                      title: 'Cultures',
                      headerAction: _addingSection == 'culture' ||
                              _editingSection == 'culture'
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
                              (c) {
                                if (_isEditingItem('culture', c.id)) {
                                  return _buildGenericEditForm(
                                    section: 'culture',
                                    title: 'Edit Culture',
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
                                  );
                                }
                                return AdmissionDetailsCultureCard(
                                  culture: c,
                                  onEdit: () => _beginEditItem(
                                    'culture',
                                    c.id,
                                    fields: {
                                      'title': c.title,
                                      'note': c.note,
                                    },
                                  ),
                                  onDelete: () => _deleteItem('cultures', c.id),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    AdmissionDetailsSectionContainer(
                      title: 'Consultations',
                      headerAction: _addingSection == 'consultation' ||
                              _editingSection == 'consultation'
                          ? null
                          : IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              onPressed: () => _startAddGeneric('consultation'),
                            ),
                      child: Column(
                        children: [
                          if (_addingSection == 'consultation')
                            AdmissionDetailsGenericAddForm(
                              title: 'Add Consultation',
                              saving: _savingGeneric,
                              onCancel: _cancelAddGeneric,
                              onSave: _saveGenericAdd,
                              fields: [
                                AdmissionDetailsFormFieldSpec(
                                  hint: 'Speciality (e.g. Cardiology)',
                                  controller: _getCtrl('speciality'),
                                  isRequired: true,
                                ),
                                AdmissionDetailsFormFieldSpec(
                                  hint: 'Reply',
                                  controller: _getCtrl('reply'),
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          if (admission.consultations.isEmpty &&
                              _addingSection != 'consultation')
                            const AdmissionDetailsEmptyHint(
                              'No consultations recorded.',
                            )
                          else
                            ...admission.consultations.map(
                              (c) {
                                if (_isEditingItem('consultation', c.id)) {
                                  return _buildGenericEditForm(
                                    section: 'consultation',
                                    title: 'Edit Consultation',
                                    fields: [
                                      AdmissionDetailsFormFieldSpec(
                                        hint: 'Speciality (e.g. Cardiology)',
                                        controller: _getCtrl('speciality'),
                                        isRequired: true,
                                      ),
                                      AdmissionDetailsFormFieldSpec(
                                        hint: 'Reply',
                                        controller: _getCtrl('reply'),
                                        maxLines: 3,
                                      ),
                                    ],
                                  );
                                }
                                return AdmissionDetailsConsultationCard(
                                  consultation: c,
                                  onEdit: () => _beginEditItem(
                                    'consultation',
                                    c.id,
                                    fields: {
                                      'speciality': c.speciality,
                                      'reply': c.reply,
                                    },
                                  ),
                                  onDelete: () =>
                                      _deleteItem('consultations', c.id),
                                );
                              },
                            ),
                        ],
                      ),
                    ),

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
    ];
  }
}
