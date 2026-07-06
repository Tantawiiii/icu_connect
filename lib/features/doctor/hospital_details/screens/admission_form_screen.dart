import 'dart:io';

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
import '../utils/admission_update_validation.dart';
import '../widgets/admission_details_consultation_card.dart';
import '../widgets/admission_details_culture_card.dart';
import '../widgets/admission_details_empty_hint.dart';
import '../widgets/admission_details_generic_add_form.dart';
import '../widgets/admission_details_measurement_section.dart';
import '../widgets/admission_details_medication_card.dart';
import '../widgets/admission_details_note_card.dart';
import '../widgets/admission_details_section_container.dart';
import '../widgets/admission_details_simple_text_card.dart';
import '../widgets/admission_details_treatment_plan_card.dart';
import '../widgets/admission_form_essentials_section.dart';
import '../widgets/admission_form_radiology_draft_card.dart';
import '../widgets/pending_measurement_column_entry.dart';

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
  final String? initialBedNumber;
  final int? hospitalGroupId;
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

  int _tempId = 1;

  final List<ClinicalNoteModel> _clinicalDrafts = [];
  final List<AdmissionFormRadiologyDraft> _radiologyDrafts = [];
  final List<TreatmentPlanModel> _treatmentDrafts = [];
  final List<MedicationModel> _medicationDrafts = [];
  final List<EchoModel> _echoDrafts = [];
  final List<UltrasoundModel> _ultrasoundDrafts = [];
  final List<CultureModel> _cultureDrafts = [];
  final List<ConsultationModel> _consultationDrafts = [];
  final Set<int> _loadedConsultationIds = {};

  final List<VitalRecordModel> _vitalDraftRecords = [];
  final List<LabRecordModel> _labDraftRecords = [];

  String? _addingSection;
  String? _editingSection;
  int? _editingItemId;
  final Map<String, TextEditingController> _genericCtrls = {};
  String? _pendingType;
  final List<String> _radiologyLocalPaths = [];

  bool _addingVital = false;
  PendingMeasurementColumnEntry? _pendingVital;
  bool _addingLab = false;
  PendingMeasurementColumnEntry? _pendingLab;

  final _picker = ImagePicker();

  bool get _isEdit => widget.admission != null;

  @override
  void initState() {
    super.initState();
    final a = widget.admission;
    _status = a != null
        ? AdmissionStatus.fromApiValue(a.status)
        : AdmissionStatus.admitted;

    if (a != null) {
      _bedCtrl.text = a.bedNumber;
      _notesCtrl.text = a.notes;
      _selectedPatient = a.patient;
      _dateComes = _parseDate(a.dateComes);
      _dateLeave = _parseDate(a.dateLeave);
      _dateOfDeath = _parseDate(a.dateOfDeath);
      _clinicalDrafts.addAll(a.clinicalNotes);
      _treatmentDrafts.addAll(a.treatmentPlans);
      _medicationDrafts.addAll(a.medications);
      _echoDrafts.addAll(a.echoes);
      _ultrasoundDrafts.addAll(a.ultrasounds);
      _cultureDrafts.addAll(a.cultures);
      _consultationDrafts.addAll(a.consultations);
      _loadedConsultationIds.addAll(a.consultations.map((c) => c.id));
      _vitalDraftRecords.addAll(a.vitals);
      _labDraftRecords.addAll(a.labs);
      _radiologyDrafts.addAll(
        a.radiologyImages.map(
          (img) => AdmissionFormRadiologyDraft(
            id: img.id,
            title: img.title,
            report: img.report,
            localMediaPaths:
                img.imagePath.isNotEmpty ? [img.imagePath] : const [],
          ),
        ),
      );
      _tempId = _nextTempIdSeed(a);
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

  String _nowIso() => DateTime.now().toIso8601String();

  int _nextTempId() => _tempId++;

  int _nextTempIdSeed(PatientAdmissionModel a) {
    var max = 0;
    void consider(int id) {
      if (id > max) max = id;
    }

    for (final item in a.clinicalNotes) {
      consider(item.id);
    }
    for (final item in a.treatmentPlans) {
      consider(item.id);
    }
    for (final item in a.medications) {
      consider(item.id);
    }
    for (final item in a.echoes) {
      consider(item.id);
    }
    for (final item in a.ultrasounds) {
      consider(item.id);
    }
    for (final item in a.cultures) {
      consider(item.id);
    }
    for (final item in a.consultations) {
      consider(item.id);
    }
    for (final item in a.vitals) {
      consider(item.id);
    }
    for (final item in a.labs) {
      consider(item.id);
    }
    for (final item in a.radiologyImages) {
      consider(item.id);
    }

    return max + 1;
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
    _disposePendingVitalColumn();
    _disposePendingLabColumn();
    for (final c in _genericCtrls.values) {
      c.dispose();
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

  TextEditingController _getCtrl(String key) {
    return _genericCtrls.putIfAbsent(key, () => TextEditingController());
  }

  void _disposeGenericCtrls() {
    for (final c in _genericCtrls.values) {
      c.dispose();
    }
    _genericCtrls.clear();
  }

  void _startAddGeneric(String section, {String? defaultType}) {
    _cancelEditGeneric();
    _disposeGenericCtrls();
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
    _disposeGenericCtrls();
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

  bool _isEditingItem(String section, int id) =>
      _editingSection == section && _editingItemId == id;

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

  void _saveGenericAddLocal() {
    if (_addingSection == null) return;
    final section = _addingSection!;
    final validationError = _validateGenericSection(section);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError), backgroundColor: AppColors.error),
      );
      return;
    }

    final now = _nowIso();
    setState(() {
      switch (section) {
        case 'med':
          _medicationDrafts.add(
            MedicationModel(
              id: _nextTempId(),
              admissionId: 0,
              type: _pendingType ?? 'other',
              title: _getCtrl('title').text.trim(),
              value: _getCtrl('value').text.trim(),
              duration: _getCtrl('duration').text.trim(),
              createdAt: now,
              updatedAt: now,
            ),
          );
        case 'clinical_note':
          _clinicalDrafts.add(
            ClinicalNoteModel(
              id: _nextTempId(),
              admissionId: 0,
              addedBy: 0,
              type: AdmissionClinicalNoteType.normalize(_pendingType),
              content: _getCtrl('content').text.trim(),
              createdAt: now,
              updatedAt: now,
            ),
          );
        case 'radiology':
          _radiologyDrafts.add(
            AdmissionFormRadiologyDraft(
              id: _nextTempId(),
              title: _getCtrl('title').text.trim(),
              report: _getCtrl('report').text.trim(),
              localMediaPaths: List<String>.from(_radiologyLocalPaths),
            ),
          );
        case 'echo':
          _echoDrafts.add(
            EchoModel(
              id: _nextTempId(),
              admissionId: 0,
              text: _getCtrl('text').text.trim(),
              createdAt: now,
              updatedAt: now,
            ),
          );
        case 'us':
          _ultrasoundDrafts.add(
            UltrasoundModel(
              id: _nextTempId(),
              admissionId: 0,
              text: _getCtrl('text').text.trim(),
              createdAt: now,
              updatedAt: now,
            ),
          );
        case 'culture':
          _cultureDrafts.add(
            CultureModel(
              id: _nextTempId(),
              admissionId: 0,
              title: _getCtrl('title').text.trim(),
              note: _getCtrl('note').text.trim(),
              createdAt: now,
              updatedAt: now,
            ),
          );
        case 'consultation':
          _consultationDrafts.add(
            ConsultationModel(
              id: _nextTempId(),
              admissionId: 0,
              speciality: _getCtrl('speciality').text.trim(),
              reply: _getCtrl('reply').text.trim(),
              createdAt: now,
              updatedAt: now,
            ),
          );
        case 'plan':
          _treatmentDrafts.add(
            TreatmentPlanModel(
              id: _nextTempId(),
              admissionId: 0,
              planContent: _getCtrl('plan').text.trim(),
              createdAt: now,
              updatedAt: now,
            ),
          );
      }
      _cancelAddGeneric();
      _disposeGenericCtrls();
    });
  }

  void _saveGenericEditLocal() {
    if (_editingSection == null || _editingItemId == null) return;
    final section = _editingSection!;
    final id = _editingItemId!;
    final validationError = _validateGenericSection(section);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError), backgroundColor: AppColors.error),
      );
      return;
    }

    final now = _nowIso();
    setState(() {
      switch (section) {
        case 'med':
          final i = _medicationDrafts.indexWhere((m) => m.id == id);
          if (i >= 0) {
            _medicationDrafts[i] = MedicationModel(
              id: id,
              admissionId: 0,
              type: _pendingType ?? 'other',
              title: _getCtrl('title').text.trim(),
              value: _getCtrl('value').text.trim(),
              duration: _getCtrl('duration').text.trim(),
              createdAt: _medicationDrafts[i].createdAt,
              updatedAt: now,
            );
          }
        case 'clinical_note':
          final i = _clinicalDrafts.indexWhere((n) => n.id == id);
          if (i >= 0) {
            _clinicalDrafts[i] = ClinicalNoteModel(
              id: id,
              admissionId: 0,
              addedBy: 0,
              type: AdmissionClinicalNoteType.normalize(_pendingType),
              content: _getCtrl('content').text.trim(),
              createdAt: _clinicalDrafts[i].createdAt,
              updatedAt: now,
            );
          }
        case 'radiology':
          final i = _radiologyDrafts.indexWhere((r) => r.id == id);
          if (i >= 0) {
            final paths = _radiologyLocalPaths.isNotEmpty
                ? List<String>.from(_radiologyLocalPaths)
                : _radiologyDrafts[i].localMediaPaths;
            _radiologyDrafts[i] = AdmissionFormRadiologyDraft(
              id: id,
              title: _getCtrl('title').text.trim(),
              report: _getCtrl('report').text.trim(),
              localMediaPaths: paths,
            );
          }
        case 'echo':
          final i = _echoDrafts.indexWhere((e) => e.id == id);
          if (i >= 0) {
            _echoDrafts[i] = EchoModel(
              id: id,
              admissionId: 0,
              text: _getCtrl('text').text.trim(),
              createdAt: _echoDrafts[i].createdAt,
              updatedAt: now,
            );
          }
        case 'us':
          final i = _ultrasoundDrafts.indexWhere((u) => u.id == id);
          if (i >= 0) {
            _ultrasoundDrafts[i] = UltrasoundModel(
              id: id,
              admissionId: 0,
              text: _getCtrl('text').text.trim(),
              createdAt: _ultrasoundDrafts[i].createdAt,
              updatedAt: now,
            );
          }
        case 'culture':
          final i = _cultureDrafts.indexWhere((c) => c.id == id);
          if (i >= 0) {
            _cultureDrafts[i] = CultureModel(
              id: id,
              admissionId: 0,
              title: _getCtrl('title').text.trim(),
              note: _getCtrl('note').text.trim(),
              createdAt: _cultureDrafts[i].createdAt,
              updatedAt: now,
            );
          }
        case 'consultation':
          final i = _consultationDrafts.indexWhere((c) => c.id == id);
          if (i >= 0) {
            _consultationDrafts[i] = ConsultationModel(
              id: id,
              admissionId: 0,
              speciality: _getCtrl('speciality').text.trim(),
              reply: _getCtrl('reply').text.trim(),
              createdAt: _consultationDrafts[i].createdAt,
              updatedAt: now,
            );
          }
        case 'plan':
          final i = _treatmentDrafts.indexWhere((p) => p.id == id);
          if (i >= 0) {
            _treatmentDrafts[i] = TreatmentPlanModel(
              id: id,
              admissionId: 0,
              planContent: _getCtrl('plan').text.trim(),
              createdAt: _treatmentDrafts[i].createdAt,
              updatedAt: now,
            );
          }
      }
      _cancelEditGeneric();
      _disposeGenericCtrls();
    });
  }

  void _deleteDraftItem(String section, int id) {
    setState(() {
      switch (section) {
        case 'clinical_note':
          _clinicalDrafts.removeWhere((n) => n.id == id);
        case 'radiology':
          _radiologyDrafts.removeWhere((r) => r.id == id);
        case 'plan':
          _treatmentDrafts.removeWhere((p) => p.id == id);
        case 'med':
          _medicationDrafts.removeWhere((m) => m.id == id);
        case 'echo':
          _echoDrafts.removeWhere((e) => e.id == id);
        case 'us':
          _ultrasoundDrafts.removeWhere((u) => u.id == id);
        case 'culture':
          _cultureDrafts.removeWhere((c) => c.id == id);
        case 'consultation':
          _consultationDrafts.removeWhere((c) => c.id == id);
      }
    });
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
      saving: false,
      onCancel: () {
        _cancelEditGeneric();
        _disposeGenericCtrls();
        setState(() {});
      },
      onSave: _saveGenericEditLocal,
      typeLabel: typeLabel,
      typeValue: _pendingType,
      types: types,
      onTypeChanged:
          types == null ? null : (v) => setState(() => _pendingType = v),
      fields: fields,
      childrenAfterFields: childrenAfterFields,
    );
  }

  Future<void> _pickRadiologyImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 80);
    if (files.isEmpty || !mounted) return;
    setState(() => _radiologyLocalPaths.addAll(files.map((f) => f.path)));
  }

  Future<void> _pickRadiologyVideo() async {
    final x = await _picker.pickVideo(source: ImageSource.gallery);
    if (x == null || !mounted) return;
    setState(() => _radiologyLocalPaths.add(x.path));
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

  void _startAddVitalColumn(List<MeasurementTitleModel> titles) {
    _cancelEditGeneric();
    _cancelAddLabColumn();
    _disposePendingVitalColumn();
    _pendingVital = PendingMeasurementColumnEntry(titles: titles);
    setState(() => _addingVital = true);
  }

  void _cancelAddVitalColumn() {
    _disposePendingVitalColumn();
    setState(() => _addingVital = false);
  }

  void _editVitalColumn(String columnKey, List<MeasurementTitleModel> titles) {
    _cancelEditGeneric();
    _cancelAddLabColumn();
    _disposePendingVitalColumn();

    final recordIds = <int, int>{};
    final values = <int, String>{};
    DateTime? columnDate;

    for (final record in _vitalDraftRecords) {
      if (_vitalColumnKey(record) != columnKey) continue;
      recordIds[record.vitalsTitleId] = record.id;
      values[record.vitalsTitleId] = record.value;
      columnDate ??=
          DateTime.tryParse(record.date) ?? DateTime.tryParse(record.createdAt);
    }

    _pendingVital = PendingMeasurementColumnEntry(
      titles: titles,
      date: columnDate ?? DateTime.now(),
      recordIdsByTitleId: recordIds,
      initialValuesByTitleId: values,
      editingColumnKey: columnKey,
    );
    setState(() => _addingVital = true);
  }

  void _saveVitalColumnLocal(List<MeasurementTitleModel> titles) {
    final pending = _pendingVital;
    if (pending == null) return;

    final items = <VitalRecordModel>[];
    final dateStr = _sqlDateTime(pending.date);
    final columnKey = pending.editingColumnKey ?? dateStr;

    for (final title in titles) {
      final text = pending.controllers[title.id]?.text.trim() ?? '';
      if (text.isEmpty) continue;
      final valueError = AdmissionUpdateValidation.measurementValue(
        raw: text,
        field: title.title,
        isNumeric: title.isNumericValueType,
      );
      if (valueError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(valueError), backgroundColor: AppColors.error),
        );
        return;
      }
      items.add(
        VitalRecordModel(
          id: pending.recordIdsByTitleId[title.id] ?? _nextTempId(),
          admissionId: 0,
          vitalsTitleId: title.id,
          value: text,
          date: dateStr,
          createdAt: dateStr,
          updatedAt: dateStr,
          vitalsTitle: title,
        ),
      );
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter at least one value'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _vitalDraftRecords.removeWhere((r) => _vitalColumnKey(r) == columnKey);
      _vitalDraftRecords.addAll(items);
      _cancelAddVitalColumn();
    });
  }

  void _startAddLabColumn(List<MeasurementTitleModel> titles) {
    _cancelEditGeneric();
    _cancelAddVitalColumn();
    _disposePendingLabColumn();
    _pendingLab = PendingMeasurementColumnEntry(titles: titles);
    setState(() => _addingLab = true);
  }

  void _cancelAddLabColumn() {
    _disposePendingLabColumn();
    setState(() => _addingLab = false);
  }

  void _editLabColumn(String columnKey, List<MeasurementTitleModel> titles) {
    _cancelEditGeneric();
    _cancelAddVitalColumn();
    _disposePendingLabColumn();

    final recordIds = <int, int>{};
    final values = <int, String>{};
    DateTime? columnDate;

    for (final record in _labDraftRecords) {
      if (_labColumnKey(record) != columnKey) continue;
      recordIds[record.labsTitleId] = record.id;
      values[record.labsTitleId] = record.value;
      columnDate ??=
          DateTime.tryParse(record.date) ?? DateTime.tryParse(record.createdAt);
    }

    _pendingLab = PendingMeasurementColumnEntry(
      titles: titles,
      date: columnDate ?? DateTime.now(),
      recordIdsByTitleId: recordIds,
      initialValuesByTitleId: values,
      editingColumnKey: columnKey,
    );
    setState(() => _addingLab = true);
  }

  void _saveLabColumnLocal(List<MeasurementTitleModel> titles) {
    final pending = _pendingLab;
    if (pending == null) return;

    final items = <LabRecordModel>[];
    final dateStr = _sqlDateTime(pending.date);
    final columnKey = pending.editingColumnKey ?? dateStr;

    for (final title in titles) {
      final text = pending.controllers[title.id]?.text.trim() ?? '';
      if (text.isEmpty) continue;
      final valueError = AdmissionUpdateValidation.numericValue(
        text,
        field: title.title,
      );
      if (valueError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(valueError), backgroundColor: AppColors.error),
        );
        return;
      }
      items.add(
        LabRecordModel(
          id: pending.recordIdsByTitleId[title.id] ?? _nextTempId(),
          admissionId: 0,
          labsTitleId: title.id,
          value: text,
          date: dateStr,
          createdAt: dateStr,
          updatedAt: dateStr,
          labsTitle: title,
        ),
      );
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter at least one value'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _labDraftRecords.removeWhere((r) => _labColumnKey(r) == columnKey);
      _labDraftRecords.addAll(items);
      _cancelAddLabColumn();
    });
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

    final clinicalDrafts = _clinicalDrafts
        .map(
          (n) => AdmissionClinicalNoteDraft(
            type: n.type,
            content: n.content,
          ),
        )
        .toList();

    final radiologyDrafts = <AdmissionRadiologyDraft>[];
    for (final draft in _radiologyDrafts) {
      final report = draft.report.isEmpty ? null : draft.report;
      if (draft.localMediaPaths.isEmpty) {
        radiologyDrafts.add(
          AdmissionRadiologyDraft(title: draft.title, report: report),
        );
      } else {
        for (final path in draft.localMediaPaths) {
          radiologyDrafts.add(
            AdmissionRadiologyDraft(
              title: draft.title,
              report: report,
              localImagePath: path,
            ),
          );
        }
      }
    }

    final treatmentDrafts = _treatmentDrafts
        .map((p) => AdmissionTreatmentDraft(planContent: p.planContent))
        .toList();

    final vitalDrafts = _vitalDraftRecords
        .map(
          (e) => AdmissionVitalDraft(
            vitalsTitleId: e.vitalsTitleId,
            value: double.tryParse(e.value) ?? 0,
            date: e.date,
          ),
        )
        .toList();

    final labDrafts = _labDraftRecords
        .map(
          (e) => AdmissionLabDraft(
            labsTitleId: e.labsTitleId,
            value: double.tryParse(e.value) ?? 0,
            date: e.date,
          ),
        )
        .toList();

    final medicationDrafts = _medicationDrafts
        .map(
          (e) => AdmissionMedicationDraft(
            type: e.type,
            title: e.title,
            value: e.value,
            duration: e.duration,
          ),
        )
        .toList();

    final echoDrafts =
        _echoDrafts.map((e) => AdmissionEchoDraft(text: e.text)).toList();

    final ultrasoundDrafts = _ultrasoundDrafts
        .map((e) => AdmissionUltrasoundDraft(text: e.text))
        .toList();

    final cultureDrafts = _cultureDrafts
        .map(
          (e) => AdmissionCultureDraft(
            title: e.title,
            note: e.note,
          ),
        )
        .toList();

    final consultationDrafts = _consultationDrafts
        .map(
          (e) => AdmissionConsultationDraft(
            id: _isEdit && _loadedConsultationIds.contains(e.id)
                ? e.id
                : null,
            speciality: e.speciality,
            reply: e.reply,
          ),
        )
        .toList();

    if (_isEdit) {
      final req = AdmissionUpdateRequest(
        bedNumber: _bedCtrl.text.trim(),
        hospitalGroupId: widget.hospitalGroupId,
        status: _status.apiValue,
        dateLeave: _dateLeave != null ? _sqlDateTime(_dateLeave!) : null,
        dateOfDeath: _dateOfDeath != null ? _sqlDateTime(_dateOfDeath!) : null,
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
        consultations: consultationDrafts,
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
        dateLeave: _dateLeave != null ? _sqlDateTime(_dateLeave!) : null,
        dateOfDeath: _dateOfDeath != null ? _sqlDateTime(_dateOfDeath!) : null,
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
        consultations: consultationDrafts,
      );
      cubit.createAdmission(req);
    }
  }

  String _appBarTitle() {
    final name = _selectedPatient?.name.trim();
    if (name != null && name.isNotEmpty) return name;
    return _isEdit ? AppTexts.editAdmission : AppTexts.createAdmission;
  }

  Widget _radiologyMediaPickers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              onPressed: _pickRadiologyImages,
              icon: const Icon(
                Icons.photo_library_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              label: const Text('Photos'),
            ),
            TextButton.icon(
              onPressed: _pickRadiologyVideo,
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
                final name = path.split(Platform.pathSeparator).last;
                return InputChip(
                  label: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onDeleted: () =>
                      setState(() => _radiologyLocalPaths.remove(path)),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildRecordSections(AdmissionFormRefsReady refs) {
    return [
      AdmissionDetailsSectionContainer(
        title: AppTexts.clinicalNotesSection,
        headerAction: _addingSection == 'clinical_note' ||
                _editingSection == 'clinical_note'
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
                saving: false,
                onCancel: () {
                  _cancelAddGeneric();
                  _disposeGenericCtrls();
                  setState(() {});
                },
                onSave: _saveGenericAddLocal,
                typeLabel: 'Note Type',
                typeValue: _pendingType,
                types: AdmissionClinicalNoteType.values,
                onTypeChanged: (v) => setState(() => _pendingType = v),
                fields: [
                  AdmissionDetailsFormFieldSpec(
                    hint: 'Content',
                    controller: _getCtrl('content'),
                    maxLines: 5,
                    isRequired: true,
                  ),
                ],
              ),
            if (_clinicalDrafts.isEmpty && _addingSection != 'clinical_note')
              const AdmissionDetailsEmptyHint(
                'No history and complaint recorded.',
              )
            else
              ..._clinicalDrafts.map((n) {
                if (_isEditingItem('clinical_note', n.id)) {
                  return _buildGenericEditForm(
                    section: 'clinical_note',
                    title: 'Edit Clinical Note',
                    typeLabel: 'Note Type',
                    types: AdmissionClinicalNoteType.values,
                    fields: [
                      AdmissionDetailsFormFieldSpec(
                        hint: 'Content',
                        controller: _getCtrl('content'),
                        maxLines: 5,
                        isRequired: true,
                      ),
                    ],
                  );
                }
                return AdmissionDetailsNoteCard(
                  note: n,
                  onEdit: () => _beginEditItem(
                    'clinical_note',
                    n.id,
                    type: n.type,
                    fields: {'content': n.content},
                  ),
                  onDelete: () => _deleteDraftItem('clinical_note', n.id),
                );
              }),
          ],
        ),
      ),
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
                saving: false,
                onCancel: () {
                  _cancelAddGeneric();
                  _disposeGenericCtrls();
                  setState(() {});
                },
                onSave: _saveGenericAddLocal,
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
                childrenAfterFields: [_radiologyMediaPickers()],
              ),
            if (_radiologyDrafts.isEmpty && _addingSection != 'radiology')
              const AdmissionDetailsEmptyHint('No radiology images recorded.')
            else ...[
              ..._radiologyDrafts
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
                  childrenAfterFields: [_radiologyMediaPickers()],
                ),
              ),
              if (_radiologyDrafts.any(
                (img) => !_isEditingItem('radiology', img.id),
              ))
                SizedBox(
                  height: 280,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _radiologyDrafts
                        .where((img) => !_isEditingItem('radiology', img.id))
                        .length,
                    separatorBuilder: (_, __) => const SizedBox(width: 0),
                    itemBuilder: (context, index) {
                      final draft = _radiologyDrafts
                          .where((img) => !_isEditingItem('radiology', img.id))
                          .elementAt(index);
                      return AdmissionFormRadiologyDraftCard(
                        draft: draft,
                        compact: true,
                        onEdit: () {
                          _radiologyLocalPaths
                            ..clear()
                            ..addAll(draft.localMediaPaths);
                          _beginEditItem(
                            'radiology',
                            draft.id,
                            fields: {
                              'title': draft.title,
                              'report': draft.report,
                            },
                          );
                        },
                        onDelete: () => _deleteDraftItem('radiology', draft.id),
                      );
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
      AdmissionDetailsSectionContainer(
        title: 'Treatment Plans',
        headerAction:
            _addingSection == 'plan' || _editingSection == 'plan'
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
                saving: false,
                onCancel: () {
                  _cancelAddGeneric();
                  _disposeGenericCtrls();
                  setState(() {});
                },
                onSave: _saveGenericAddLocal,
                fields: [
                  AdmissionDetailsFormFieldSpec(
                    hint: 'Plan content',
                    controller: _getCtrl('plan'),
                    maxLines: 4,
                    isRequired: true,
                  ),
                ],
              ),
            if (_treatmentDrafts.isEmpty && _addingSection != 'plan')
              const AdmissionDetailsEmptyHint('No treatment plans recorded.')
            else
              ..._treatmentDrafts.map((p) {
                if (_isEditingItem('plan', p.id)) {
                  return _buildGenericEditForm(
                    section: 'plan',
                    title: 'Edit Treatment Plan',
                    fields: [
                      AdmissionDetailsFormFieldSpec(
                        hint: 'Plan content',
                        controller: _getCtrl('plan'),
                        maxLines: 4,
                        isRequired: true,
                      ),
                    ],
                  );
                }
                return AdmissionDetailsTreatmentPlanCard(
                  plan: p,
                  onEdit: () => _beginEditItem(
                    'plan',
                    p.id,
                    fields: {'plan': p.planContent},
                  ),
                  onDelete: () => _deleteDraftItem('plan', p.id),
                );
              }),
          ],
        ),
      ),
      AdmissionDetailsMeasurementSection(
        title: AppTexts.vitalSigns,
        isLabs: false,
        records: _vitalDraftRecords,
        titles: refs.vitalsTitles,
        addingColumn: _addingVital,
        saving: false,
        pendingColumn: _pendingVital,
        onStartAddColumn: () => _startAddVitalColumn(refs.vitalsTitles),
        onCancelAddColumn: _cancelAddVitalColumn,
        onSaveColumn: () => _saveVitalColumnLocal(refs.vitalsTitles),
        onEditColumn: (key) => _editVitalColumn(key, refs.vitalsTitles),
        onPickColumnDate: () => _pickDateTime(
          initial: _pendingVital?.date,
          onPick: (d) => setState(() => _pendingVital?.date = d),
        ),
      ),
      AdmissionDetailsMeasurementSection(
        title: AppTexts.labs,
        isLabs: true,
        records: _labDraftRecords,
        titles: refs.labsTitles,
        addingColumn: _addingLab,
        saving: false,
        pendingColumn: _pendingLab,
        onStartAddColumn: () => _startAddLabColumn(refs.labsTitles),
        onCancelAddColumn: _cancelAddLabColumn,
        onSaveColumn: () => _saveLabColumnLocal(refs.labsTitles),
        onEditColumn: (key) => _editLabColumn(key, refs.labsTitles),
        onPickColumnDate: () => _pickDateTime(
          initial: _pendingLab?.date,
          onPick: (d) => setState(() => _pendingLab?.date = d),
        ),
      ),
      AdmissionDetailsSectionContainer(
        title: 'Medications',
        headerAction:
            _addingSection == 'med' || _editingSection == 'med'
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
                saving: false,
                onCancel: () {
                  _cancelAddGeneric();
                  _disposeGenericCtrls();
                  setState(() {});
                },
                onSave: _saveGenericAddLocal,
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
                onTypeChanged: (v) => setState(() => _pendingType = v),
              ),
            if (_medicationDrafts.isEmpty && _addingSection != 'med')
              const AdmissionDetailsEmptyHint('No medications recorded.')
            else
              ..._medicationDrafts.map((m) {
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
                  onDelete: () => _deleteDraftItem('med', m.id),
                );
              }),
          ],
        ),
      ),
      AdmissionDetailsSectionContainer(
        title: 'Echo',
        headerAction:
            _addingSection == 'echo' || _editingSection == 'echo'
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
                saving: false,
                onCancel: () {
                  _cancelAddGeneric();
                  _disposeGenericCtrls();
                  setState(() {});
                },
                onSave: _saveGenericAddLocal,
                fields: [
                  AdmissionDetailsFormFieldSpec(
                    hint: 'Note text',
                    controller: _getCtrl('text'),
                    maxLines: 3,
                    isRequired: true,
                  ),
                ],
              ),
            if (_echoDrafts.isEmpty && _addingSection != 'echo')
              const AdmissionDetailsEmptyHint('No echo findings recorded.')
            else
              ..._echoDrafts.map((e) {
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
                  onDelete: () => _deleteDraftItem('echo', e.id),
                );
              }),
          ],
        ),
      ),
      AdmissionDetailsSectionContainer(
        title: 'Ultrasound',
        headerAction:
            _addingSection == 'us' || _editingSection == 'us'
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
                saving: false,
                onCancel: () {
                  _cancelAddGeneric();
                  _disposeGenericCtrls();
                  setState(() {});
                },
                onSave: _saveGenericAddLocal,
                fields: [
                  AdmissionDetailsFormFieldSpec(
                    hint: 'Note text',
                    controller: _getCtrl('text'),
                    maxLines: 3,
                    isRequired: true,
                  ),
                ],
              ),
            if (_ultrasoundDrafts.isEmpty && _addingSection != 'us')
              const AdmissionDetailsEmptyHint('No ultrasound findings recorded.')
            else
              ..._ultrasoundDrafts.map((u) {
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
                  onDelete: () => _deleteDraftItem('us', u.id),
                );
              }),
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
                saving: false,
                onCancel: () {
                  _cancelAddGeneric();
                  _disposeGenericCtrls();
                  setState(() {});
                },
                onSave: _saveGenericAddLocal,
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
            if (_cultureDrafts.isEmpty && _addingSection != 'culture')
              const AdmissionDetailsEmptyHint('No cultures recorded.')
            else
              ..._cultureDrafts.map((c) {
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
                  onDelete: () => _deleteDraftItem('culture', c.id),
                );
              }),
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
                saving: false,
                onCancel: () {
                  _cancelAddGeneric();
                  _disposeGenericCtrls();
                  setState(() {});
                },
                onSave: _saveGenericAddLocal,
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
            if (_consultationDrafts.isEmpty &&
                _addingSection != 'consultation')
              const AdmissionDetailsEmptyHint('No consultations recorded.')
            else
              ..._consultationDrafts.map((c) {
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
                  onDelete: () => _deleteDraftItem('consultation', c.id),
                );
              }),
          ],
        ),
      ),
      AdmissionDetailsSectionContainer(
        title: AppTexts.admissionNotesSection,
        child: AppTextField(
          controller: _notesCtrl,
          hintText: AppTexts.notAvailable,
          maxLines: 4,
        ),
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
                    ..._buildRecordSections(refs),
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
