import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart' deferred as printing;

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/confirm_action_dialog.dart';

import '../../../superAdmin/patients/models/admission_request_model.dart';
import '../../../superAdmin/patients/models/patient_admission_models.dart';
import '../../ai_recommendations/ai_recommendations.dart';
import '../data/default_patient_lab_titles.dart';
import '../enums/admission_status.dart';
import '../utils/admission_update_validation.dart';
import '../models/admission_timeline_note.dart';
import '../repository/hospital_admissions_repository.dart';
import '../services/admission_pdf_builder.dart' deferred as pdf_builder;
import 'admission_activity_history_screen.dart';
import '../widgets/admission_exit_outcome_sheet.dart';
import '../widgets/add_patient_measurement_title_sheet.dart';
import '../widgets/admission_cultures_section.dart';
import '../widgets/admission_details_app_bar_actions.dart';
import '../widgets/admission_details_clinical_notes_section.dart';
import '../widgets/admission_details_consultations_section.dart';
import '../widgets/admission_details_formatters.dart';
import '../widgets/admission_details_generic_add_form.dart';
import '../widgets/admission_details_info_chips_section.dart';
import '../widgets/admission_details_measurement_section.dart';
import '../widgets/admission_details_patient_header_section.dart';
import '../widgets/admission_details_radiology_section.dart';
import '../widgets/admission_details_section_container.dart';
import '../widgets/admission_details_simple_findings_section.dart';
import '../widgets/admission_medications_section.dart';
import '../widgets/admission_plans_section.dart';
import '../widgets/admission_radiology_media_picker.dart';
import '../widgets/admission_timeline_notes_section.dart';
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

  List<AdmissionTimelineNote> _timelineNotes = const [];
  bool _loadingTimelineNotes = false;
  bool _sendingTimelineNote = false;

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

  final Map<int, bool> _medicationDiscontinuedOverrides = {};
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
        _syncMedicationDiscontinuedOverrides(data.medications);
      });
      _loadTitles(data.patientId);
      _loadTimelineNotes();
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

  List<MedicationModel> _medicationsForDisplay(List<MedicationModel> meds) {
    return meds
        .map((m) {
          final override = _medicationDiscontinuedOverrides[m.id];
          if (override == null) return m;
          return m.copyWith(isDiscontinued: override);
        })
        .toList(growable: false);
  }

  void _syncMedicationDiscontinuedOverrides(List<MedicationModel> meds) {
    for (final med in meds) {
      final override = _medicationDiscontinuedOverrides[med.id];
      if (override == null) continue;
      if (med.isDiscontinued == override) {
        _medicationDiscontinuedOverrides.remove(med.id);
      }
    }
  }

  Future<void> _loadTimelineNotes() async {
    setState(() => _loadingTimelineNotes = true);
    try {
      final notes = await _repo.fetchAdmissionNotes(widget.admissionId);
      if (!mounted) return;
      setState(() {
        _timelineNotes = notes;
        _loadingTimelineNotes = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _loadingTimelineNotes = false);
      _showSnack(e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingTimelineNotes = false);
      _showSnack('Could not load timeline notes', isError: true);
    }
  }

  Future<void> _sendTimelineNote(String content) async {
    final text = content.trim();
    if (text.isEmpty) {
      _showSnack(AppTexts.timelineNoteRequired, isError: true);
      return;
    }
    setState(() => _sendingTimelineNote = true);
    try {
      final created = await _repo.createAdmissionNote(
        widget.admissionId,
        content: text,
      );
      if (!mounted) return;
      setState(() {
        _timelineNotes = [created, ..._timelineNotes];
        _sendingTimelineNote = false;
      });
      _showSnack(AppTexts.timelineNoteAdded);
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _sendingTimelineNote = false);
      _showSnack(e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sendingTimelineNote = false);
      _showSnack('Could not add note', isError: true);
    }
  }

  void _openClinicalTimeline() {
    if (_timelineNotes.isEmpty && !_loadingTimelineNotes) {
      _loadTimelineNotes();
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> refresh() async {
              await _loadTimelineNotes();
              setSheetState(() {});
            }

            Future<void> send(String content) async {
              await _sendTimelineNote(content);
              setSheetState(() {});
            }

            final media = MediaQuery.of(context);
            final keyboard = media.viewInsets.bottom;
            final availableHeight = media.size.height - keyboard;
            final sheetHeight = (availableHeight * 0.92).clamp(
              280.0,
              availableHeight,
            );

            return AnimatedPadding(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: keyboard),
              child: SizedBox(
                height: sheetHeight,
                child: AdmissionTimelineNotesSection(
                  asSheet: true,
                  notes: _timelineNotes,
                  loading: _loadingTimelineNotes,
                  sending: _sendingTimelineNote,
                  onRefresh: refresh,
                  onSend: send,
                  onOpenAiAssistant: _openAiRecommendations,
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openAiRecommendations() {
    final admission = _admission;
    if (admission == null) return;
    showAdmissionAiRecommendationsSheet(
      context: context,
      admissionId: admission.id,
      patientName: admission.patient?.name,
      onApplied: () {
        _silentRefreshAdmission();
        _loadTimelineNotes();
      },
    );
  }

  void _openActivityHistory() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            AdmissionActivityHistoryScreen(admissionId: widget.admissionId),
      ),
    );
  }

  Future<void> _refreshAdmission() async {
    if (_editingPatient) _cancelPatientEdit();
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
      // pdf/printing are large, rarely-used packages: only load their code
      // when the user actually asks to export a PDF.
      await Future.wait([pdf_builder.loadLibrary(), printing.loadLibrary()]);
      final bytes = await pdf_builder.AdmissionPdfBuilder.build(
        admission: admission,
      );

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
      await printing.Printing.sharePdf(bytes: bytes, filename: fileName);
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
      final created = (await _repo.createPatientVitalTitle(
        patientId: patientId,
        title: values.title,
        unit: values.unit,
        valueType: values.valueType,
        normalRangeMin: values.normalRangeMin,
        normalRangeMax: values.normalRangeMax,
      )).copyWith(valueType: values.valueType);
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
      final created = (await _repo.createPatientLabTitle(
        patientId: patientId,
        title: values.title,
        unit: values.unit,
        valueType: values.valueType,
        normalRangeMin: values.normalRangeMin,
        normalRangeMax: values.normalRangeMax,
      )).copyWith(valueType: values.valueType);
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
            title.title.trim().toLowerCase() ==
            preset.title.trim().toLowerCase(),
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
          drugId: null,
          dose: _getCtrl('value').text,
          frequency: _getCtrl('duration').text,
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
    final files = await _imagePicker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1920,
    );
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

  Future<void> _saveMedicationEntry({
    required int drugId,
    required String title,
    required String dose,
    required int? doseUnitId,
    required String frequency,
    String type = 'other',
    int? editingId,
  }) async {
    setState(() => _savingGeneric = true);
    try {
      final item = <String, dynamic>{
        'drug_id': drugId,
        'dose': dose,
        if (doseUnitId != null) 'dose_unit_id': doseUnitId,
        'frequency': frequency,
        'type': type,
      };
      if (editingId != null) item['id'] = editingId;
      await _repo.updateAdmissionRaw(widget.admissionId, {
        'medications': [item],
      });
      if (!mounted) return;
      _showSnack(editingId == null ? 'Entry added' : AppTexts.entryUpdated);
      if (editingId == null) {
        _cancelAddGeneric();
      } else {
        _cancelEditGeneric();
      }
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

  Future<void> _saveCultureEntry({
    required String title,
    required String note,
    required List<CultureAntibioticDraftEntry> antibiotics,
    required List<int> deletedAntibioticIds,
    int? editingId,
  }) async {
    setState(() => _savingGeneric = true);
    try {
      final antibioticPayload = <Map<String, dynamic>>[
        ...antibiotics.map((a) => a.toApiJson(includeId: editingId != null)),
        ...deletedAntibioticIds.map(
          (id) => <String, dynamic>{'id': id, '_delete': true},
        ),
      ];
      final item = <String, dynamic>{
        'title': title,
        'note': note,
        if (antibioticPayload.isNotEmpty) 'antibiotics': antibioticPayload,
      };
      if (editingId != null) item['id'] = editingId;
      await _repo.updateAdmissionRaw(widget.admissionId, {
        'cultures': [item],
      });
      if (!mounted) return;
      _showSnack(editingId == null ? 'Entry added' : AppTexts.entryUpdated);
      if (editingId == null) {
        _cancelAddGeneric();
      } else {
        _cancelEditGeneric();
      }
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

  Future<void> _saveGenericAdd() async {
    if (_addingSection == null) return;
    final section = _addingSection!;
    // Medications go through AdmissionMedicationsSection → _saveMedicationEntry.
    if (section == 'med') return;
    final validationError = _validateGenericSection(section);
    if (validationError != null) {
      _showSnack(validationError, isError: true);
      return;
    }

    setState(() => _savingGeneric = true);
    try {
      final body = <String, dynamic>{};

      if (section == 'clinical_note') {
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
          {'title': title, if (report.isNotEmpty) 'report': report},
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

  Future<void> _setMedicationDiscontinued(
    MedicationModel med, {
    required bool discontinued,
  }) async {
    setState(() => _medicationDiscontinuedOverrides[med.id] = discontinued);
    try {
      final item = <String, dynamic>{
        'id': med.id,
        'is_discontinued': discontinued,
        if (med.drugId != null) 'drug_id': med.drugId,
        if (med.value.trim().isNotEmpty) 'dose': med.value.trim(),
        if (med.doseUnitId != null) 'dose_unit_id': med.doseUnitId,
        if (med.duration.trim().isNotEmpty) 'frequency': med.duration.trim(),
        if (med.type.trim().isNotEmpty) 'type': med.type.trim(),
      };
      await _repo.updateAdmissionRaw(widget.admissionId, {
        'medications': [item],
      });
      if (!mounted) return;
      _showSnack(
        discontinued
            ? AppTexts.medicationDiscontinued
            : AppTexts.medicationResumed,
      );
      _silentRefreshAdmission();
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _medicationDiscontinuedOverrides.remove(med.id));
      _showSnack(e.message, isError: true);
    }
  }

  Future<void> _deleteItem(String sectionKey, int itemId) async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: 'Delete Entry?',
      message: 'Are you sure you want to delete this record?',
      confirmLabel: 'Delete',
    );
    if (!confirmed) return;

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
      columnDate ??=
          DateTime.tryParse(record.date) ?? DateTime.tryParse(record.createdAt);
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
      columnDate ??=
          DateTime.tryParse(record.date) ?? DateTime.tryParse(record.createdAt);
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
        'labs_title_id': title.id,
        'value': parsedValue,
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

    final confirmed = await ConfirmActionDialog.show(
      context,
      title: 'Confirm exit',
      message: 'Mark this patient as ${status.dischargedScreenLabel}?',
      confirmLabel: status.dischargedScreenLabel,
      isDestructive: false,
    );
    if (!confirmed || !mounted) return;

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
            AdmissionDetailsAppBarActions(
              exportingPdf: _exportingPdf,
              exitingAdmission: _exitingAdmission,
              canEditPatient: admission.patient != null,
              canExit: !AdmissionStatus.isDischargedOutcome(admission.status),
              onOpenAiAssistant: _openAiRecommendations,
              onExportPdf: () => _exportAdmissionPdf(admission),
              onActivityHistory: _openActivityHistory,
              onEditPatient: () {
                final p = admission.patient;
                if (p != null) _beginPatientEdit(p);
              },
              onExit: () => _exitAdmission(admission),
            ),
        ],
      ),
      body: SafeArea(child: _buildBody(admission)),
      floatingActionButton: admission == null
          ? null
          : FloatingActionButton.extended(
              heroTag: 'timeline_fab',
              onPressed: _openClinicalTimeline,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.forum_outlined),
              label: Text(
                _timelineNotes.isEmpty
                    ? AppTexts.clinicalTimelineSection
                    : '${AppTexts.clinicalTimelineSection} (${_timelineNotes.length})',
              ),
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
              const Icon(Icons.error_outline, size: 42, color: AppColors.error),
              const SizedBox(height: 10),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              AppButton(label: AppTexts.retry, onPressed: _loadAdmission),
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
    final editingRadiology = <RadiologyImageModel>[];
    final nonEditingRadiology = <RadiologyImageModel>[];
    for (final img in admission.radiologyImages) {
      if (_isEditingItem('radiology', img.id)) {
        editingRadiology.add(img);
      } else {
        nonEditingRadiology.add(img);
      }
    }

    return [
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
        onBloodGroupChanged: (v) => setState(() => _patientEditBloodGroup = v),
        onBeginEdit: admission.patient != null
            ? () => _beginPatientEdit(admission.patient!)
            : null,
        onCancel: _cancelPatientEdit,
        onSave: admission.patient != null
            ? () => _savePatientEdit(admission.patient!.id)
            : null,
      ),
      const Divider(height: 24),
      AdmissionAiAssistantCard(onOpen: _openAiRecommendations),
      const Divider(height: 24),

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
        onStartAdd: (type) =>
            _startAddGeneric('clinical_note', defaultType: type),
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
      AdmissionDetailsRadiologySection(
        editingImages: editingRadiology,
        nonEditingImages: nonEditingRadiology,
        adding: _addingSection == 'radiology',
        headerActionVisible:
            _addingSection != 'radiology' && _editingSection != 'radiology',
        onStartAdd: () => _startAddGeneric('radiology'),
        addForm: AdmissionDetailsGenericAddForm(
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
            AdmissionRadiologyMediaPicker(
              localPaths: _radiologyLocalPaths,
              saving: _savingGeneric,
              onPickImages: _pickRadiologyImages,
              onPickVideo: _pickRadiologyVideo,
              onRemove: (path) =>
                  setState(() => _radiologyLocalPaths.remove(path)),
            ),
          ],
        ),
        editForm: _buildGenericEditForm(
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
        onBeginEdit: (img) => _beginEditItem(
          'radiology',
          img.id,
          fields: {'title': img.title, 'report': img.report},
        ),
        onDelete: (id) => _deleteItem('radiology_images', id),
      ),

      // ── Plans ────────────────────────────────────────────────
      AdmissionPlansSection(
        plans: admission.treatmentPlans,
        adding: _addingSection == 'plan',
        editingItemId: _editingSection == 'plan' ? _editingItemId : null,
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
        onBeginEdit: (plan) =>
            _beginEditItem('plan', plan.id, fields: {'plan': plan.planContent}),
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

      AdmissionMedicationsSection(
        medications: _medicationsForDisplay(admission.medications),
        adding: _addingSection == 'med',
        editingItemId: _editingSection == 'med' ? _editingItemId : null,
        saving: _savingGeneric,
        onStartAdd: () => _startAddGeneric('med', defaultType: 'other'),
        onCancelAdd: _cancelAddGeneric,
        onSaveAdd:
            ({
              required drugId,
              required title,
              required dose,
              required doseUnitId,
              required frequency,
              type = 'other',
            }) => _saveMedicationEntry(
              drugId: drugId,
              title: title,
              dose: dose,
              doseUnitId: doseUnitId,
              frequency: frequency,
              type: type,
            ),
        onBeginEdit: (med) => _beginEditItem(
          'med',
          med.id,
          type: med.type,
          fields: {
            'title': med.title,
            'value': med.value,
            'duration': med.duration,
          },
        ),
        onCancelEdit: () {
          _cancelEditGeneric();
          for (final c in _genericCtrls.values) {
            c.dispose();
          }
          _genericCtrls.clear();
          setState(() {});
        },
        onSaveEdit:
            ({
              required drugId,
              required title,
              required dose,
              required doseUnitId,
              required frequency,
              type = 'other',
            }) => _saveMedicationEntry(
              drugId: drugId,
              title: title,
              dose: dose,
              doseUnitId: doseUnitId,
              frequency: frequency,
              type: type,
              editingId: _editingItemId,
            ),
        onDiscontinue: (med) =>
            _setMedicationDiscontinued(med, discontinued: !med.isDiscontinued),
        onDelete: (med) => _deleteItem('medications', med.id),
      ),

      AdmissionDetailsSimpleFindingsSection(
        title: 'Echo',
        emptyHint: 'No echo findings recorded.',
        items: admission.echoes
            .map(
              (e) => SimpleFindingItem(
                id: e.id,
                text: e.text,
                createdAt: e.createdAt,
              ),
            )
            .toList(),
        adding: _addingSection == 'echo',
        editingItemId: _editingSection == 'echo' ? _editingItemId : null,
        onStartAdd: () => _startAddGeneric('echo'),
        addForm: AdmissionDetailsGenericAddForm(
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
        editForm: _buildGenericEditForm(
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
        ),
        onBeginEdit: (item) =>
            _beginEditItem('echo', item.id, fields: {'text': item.text}),
        onDelete: (id) => _deleteItem('echo', id),
      ),
      AdmissionDetailsSimpleFindingsSection(
        title: 'Ultrasound',
        emptyHint: 'No ultrasound findings recorded.',
        items: admission.ultrasounds
            .map(
              (u) => SimpleFindingItem(
                id: u.id,
                text: u.text,
                createdAt: u.createdAt,
              ),
            )
            .toList(),
        adding: _addingSection == 'us',
        editingItemId: _editingSection == 'us' ? _editingItemId : null,
        onStartAdd: () => _startAddGeneric('us'),
        addForm: AdmissionDetailsGenericAddForm(
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
        editForm: _buildGenericEditForm(
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
        ),
        onBeginEdit: (item) =>
            _beginEditItem('us', item.id, fields: {'text': item.text}),
        onDelete: (id) => _deleteItem('ultrasounds', id),
      ),
      AdmissionCulturesSection(
        cultures: admission.cultures,
        adding: _addingSection == 'culture',
        editingItemId: _editingSection == 'culture' ? _editingItemId : null,
        saving: _savingGeneric,
        onStartAdd: () => _startAddGeneric('culture'),
        onCancelAdd: _cancelAddGeneric,
        onSaveAdd:
            ({
              required title,
              required note,
              required antibiotics,
              required deletedAntibioticIds,
            }) => _saveCultureEntry(
              title: title,
              note: note,
              antibiotics: antibiotics,
              deletedAntibioticIds: deletedAntibioticIds,
            ),
        onBeginEdit: (culture) => _beginEditItem(
          'culture',
          culture.id,
          fields: {'title': culture.title, 'note': culture.note},
        ),
        onCancelEdit: () {
          _cancelEditGeneric();
          for (final c in _genericCtrls.values) {
            c.dispose();
          }
          _genericCtrls.clear();
          setState(() {});
        },
        onSaveEdit:
            ({
              required title,
              required note,
              required antibiotics,
              required deletedAntibioticIds,
            }) => _saveCultureEntry(
              title: title,
              note: note,
              antibiotics: antibiotics,
              deletedAntibioticIds: deletedAntibioticIds,
              editingId: _editingItemId,
            ),
        onDelete: (id) => _deleteItem('cultures', id),
      ),
      AdmissionDetailsConsultationsSection(
        consultations: admission.consultations,
        adding: _addingSection == 'consultation',
        editingItemId:
            _editingSection == 'consultation' ? _editingItemId : null,
        onStartAdd: () => _startAddGeneric('consultation'),
        addForm: AdmissionDetailsGenericAddForm(
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
        editForm: _buildGenericEditForm(
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
        ),
        onBeginEdit: (c) => _beginEditItem(
          'consultation',
          c.id,
          fields: {'speciality': c.speciality, 'reply': c.reply},
        ),
        onDelete: (id) => _deleteItem('consultations', id),
      ),

      if (admission.doctor != null)
        AdmissionDetailsInfoChipsSection(
          title: 'Doctor',
          chips: [
            AdmissionDetailsInfoChip(
              label: 'Name',
              value: admission.doctor!.name,
              icon: Icons.person_outline,
            ),
            AdmissionDetailsInfoChip(
              label: 'Email',
              value: admission.doctor!.email,
              icon: Icons.email_outlined,
            ),
            AdmissionDetailsInfoChip(
              label: 'Phone',
              value: admission.doctor!.phone.isEmpty
                  ? AppTexts.notAvailable
                  : admission.doctor!.phone,
              icon: Icons.phone_outlined,
            ),
          ],
        ),
      if (admission.hospitalGroup != null)
        AdmissionDetailsInfoChipsSection(
          title: 'Ward / Group',
          chips: [
            AdmissionDetailsInfoChip(
              label: 'Name',
              value: admission.hospitalGroup!.name,
              icon: Icons.business,
            ),
            AdmissionDetailsInfoChip(
              label: 'Total beds',
              value: '${admission.hospitalGroup!.totalBeds}',
              icon: Icons.bed_outlined,
            ),
            AdmissionDetailsInfoChip(
              label: 'Available beds',
              value: '${admission.hospitalGroup!.availableBeds}',
              icon: Icons.event_available,
            ),
          ],
        ),
      AdmissionDetailsSectionContainer(
        title: AppTexts.admissionNotesSection,
        child: Text(
          admission.notes.isEmpty ? AppTexts.notAvailable : admission.notes,
          style: const TextStyle(color: AppColors.textPrimary, height: 1.5),
        ),
      ),

      const SizedBox(height: 24),
    ];
  }
}
