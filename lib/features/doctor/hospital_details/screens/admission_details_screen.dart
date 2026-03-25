import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/network/api_constants.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/core/widgets/app_button.dart';

import '../../../superAdmin/patients/models/patient_admission_models.dart';
import '../repository/hospital_admissions_repository.dart';
import 'admission_form_screen.dart';


const String _storageBaseUrl = ApiConstants.imageBaseUrl;

class AdmissionDetailsScreen extends StatefulWidget {
  const AdmissionDetailsScreen({super.key, required this.admissionId});

  final int admissionId;

  @override
  State<AdmissionDetailsScreen> createState() => _AdmissionDetailsScreenState();
}

class _AdmissionDetailsScreenState extends State<AdmissionDetailsScreen> {
  late Future<PatientAdmissionModel> _admissionFuture;

  @override
  void initState() {
    super.initState();
    _loadAdmission();
  }

  void _loadAdmission() {
    setState(() {
      _admissionFuture = const HospitalAdmissionsRepository().getAdmission(widget.admissionId);
    });
  }

  void _deleteAdmission(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Admission'),
        content: const Text('Are you sure you want to delete this admission? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      try {
        await const HospitalAdmissionsRepository().deleteAdmission(widget.admissionId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admission deleted successfully'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context, true); // Pop back to list and signal refresh
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
        );
      }
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
                onSelected: (val) async {
                  if (val == 'edit') {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdmissionFormScreen(
                          hospitalId: admission.hospitalId,
                          admission: admission,
                        ),
                      ),
                    );
                    if (updated == true) _loadAdmission();
                  } else if (val == 'delete') {
                    _deleteAdmission(context);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
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
              final message = snapshot.error is NetworkException
                  ? (snapshot.error as NetworkException).message
                  : 'Failed to load admission.';
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 42, color: AppColors.error),
                      const SizedBox(height: 10),
                      Text(message,
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
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

            return _AdmissionBody(admission: admission);
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Body – scrollable content
// ═══════════════════════════════════════════════════════════════════════════════
class _AdmissionBody extends StatelessWidget {
  const _AdmissionBody({required this.admission});

  final PatientAdmissionModel admission;

  @override
  Widget build(BuildContext context) {
    // Split clinical notes by type
    final historyNotes = admission.clinicalNotes
        .where((n) => n.type == 'history_complaint')
        .toList();
    final progressNotes = admission.clinicalNotes
        .where((n) => n.type == 'progress_note')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Patient Header ──────────────────────────────────────────────
          _PatientHeader(admission: admission),
          const Divider(height: 24),

          // ── History & Complaint ─────────────────────────────────────────
          _SectionContainer(
            title: AppTexts.historyAndComplaint,
            child: historyNotes.isEmpty
                ? const _EmptyHint('No history or complaint recorded.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: historyNotes
                        .map((n) => _NoteCard(note: n))
                        .toList(),
                  ),
          ),

          // ── Progress Notes ─────────────────────────────────────────────
          _SectionContainer(
            title: AppTexts.progressNote,
            child: progressNotes.isEmpty
                ? const _EmptyHint('No progress notes recorded.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: progressNotes
                        .map((n) => _NoteCard(note: n))
                        .toList(),
                  ),
          ),

          // ── Radiology ──────────────────────────────────────────────────
          _SectionContainer(
            title: AppTexts.radiology,
            child: admission.radiologyImages.isEmpty
                ? const _EmptyHint('No radiology images available.')
                : Column(
                    children: admission.radiologyImages
                        .map((img) => _RadiologyCard(image: img))
                        .toList(),
                  ),
          ),

          // ── Treatment Plans ────────────────────────────────────────────
          _SectionContainer(
            title: AppTexts.plans,
            child: admission.treatmentPlans.isEmpty
                ? const _EmptyHint('No treatment plans defined.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: admission.treatmentPlans
                        .map((p) => _TreatmentPlanCard(plan: p))
                        .toList(),
                  ),
          ),

          // ── Vital Signs Table ──────────────────────────────────────────
          _SectionContainer(
            title: AppTexts.vitalSigns,
            child: admission.vitals.isEmpty
                ? const _EmptyHint('No vital signs recorded.')
                : _MeasurementTable(
                    records: admission.vitals.map((v) {
                      final title = v.vitalsTitle;
                      return _MeasurementRow(
                        title: title?.title.toUpperCase() ??
                            AppTexts.defaultVitalMeasurementTitle,
                        value: v.value,
                        unit: title?.unit ?? '',
                        normalMin: title?.normalRangeMin ?? '',
                        normalMax: title?.normalRangeMax ?? '',
                        date: v.date,
                      );
                    }).toList(),
                  ),
          ),

          // ── Labs Table ─────────────────────────────────────────────────
          _SectionContainer(
            title: AppTexts.labs,
            child: admission.labs.isEmpty
                ? const _EmptyHint('No lab results recorded.')
                : _MeasurementTable(
                    records: admission.labs.map((l) {
                      final title = l.labsTitle;
                      return _MeasurementRow(
                        title: title?.title.toUpperCase() ??
                            AppTexts.defaultLabMeasurementTitle,
                        value: l.value,
                        unit: title?.unit ?? '',
                        normalMin: title?.normalRangeMin ?? '',
                        normalMax: title?.normalRangeMax ?? '',
                        date: l.date,
                      );
                    }).toList(),
                  ),
          ),

          // ── Admission Notes ────────────────────────────────────────────
          _SectionContainer(
            title: AppTexts.admissionNotesSection,
            child: Text(
              admission.notes.isEmpty ? AppTexts.notAvailable : admission.notes,
              style: const TextStyle(
                  color: AppColors.textPrimary, height: 1.5),
            ),
          ),

          // ── Doctor & Hospital Info ─────────────────────────────────────
          if (admission.doctor != null || admission.hospital != null)
            const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (admission.doctor != null)
                Expanded(
                  child: _InfoCard(
                    icon: Icons.medical_services_rounded,
                    title: 'Doctor',
                    rows: [
                      _KV(AppTexts.name, admission.doctor!.name),
                      _KV(AppTexts.emailLabel, admission.doctor!.email),
                      _KV(
                          AppTexts.phone,
                          admission.doctor!.phone.isEmpty
                              ? AppTexts.notAvailable
                              : admission.doctor!.phone),
                    ],
                  ),
                ),
              if (admission.doctor != null && admission.hospital != null)
                const SizedBox(width: 12),
              if (admission.hospital != null)
                Expanded(
                  child: _InfoCard(
                    icon: Icons.local_hospital_rounded,
                    title: 'Hospital',
                    rows: [
                      _KV(AppTexts.name, admission.hospital!.name),
                      _KV(AppTexts.location, admission.hospital!.location),
                      _KV(AppTexts.totalBeds,
                          '${admission.hospital!.totalBeds}'),
                      _KV(AppTexts.availableBeds,
                          '${admission.hospital!.availableBeds}'),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Patient Header
// ═══════════════════════════════════════════════════════════════════════════════
class _PatientHeader extends StatelessWidget {
  const _PatientHeader({required this.admission});
  final PatientAdmissionModel admission;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'admitted':
        return AppColors.success;
      case 'discharged':
        return Colors.orange;
      case 'deceased':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = admission.patient;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First row – bed chip + name
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                admission.bedNumber.isEmpty
                    ? AppTexts.notAvailable
                    : admission.bedNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(admission.status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                admission.status.isEmpty
                    ? AppTexts.notAvailable
                    : admission.status[0].toUpperCase() +
                        admission.status.substring(1),
                style: TextStyle(
                  color: _statusColor(admission.status),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
            const Spacer(),
            Text(
              patient?.name ?? AppTexts.notAvailable,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Second row – meta info
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            _MetaChip(
                label: AppTexts.admitted,
                value: _formatDate(admission.dateComes)),
            if (patient != null) ...[
              _MetaChip(label: AppTexts.age, value: '${patient.age}'),
              _MetaChip(label: AppTexts.gender, value: patient.gender),
              _MetaChip(label: AppTexts.bloodGroup, value: patient.bloodGroup),
              _MetaChip(label: AppTexts.phone, value: patient.phone),
              _MetaChip(label: AppTexts.nationalId, value: patient.nationalId),
            ],
            if (admission.dateLeave != null)
              _MetaChip(
                  label: AppTexts.dischargedLabel,
                  value: _formatDate(admission.dateLeave)),
            if (admission.dateOfDeath != null)
              _MetaChip(
                  label: AppTexts.dateOfDeathLabel,
                  value: _formatDate(admission.dateOfDeath)),
          ],
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label : $value',
      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Reusable section container – matches patient_detail_screen style
// ═══════════════════════════════════════════════════════════════════════════════
class _SectionContainer extends StatelessWidget {
  const _SectionContainer({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE0E0E0).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Clinical note card
// ═══════════════════════════════════════════════════════════════════════════════
class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});
  final ClinicalNoteModel note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            note.content,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 6),
          Text(
            _formatDateTime(note.createdAt),
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Radiology image card – tappable for full-screen view
// ═══════════════════════════════════════════════════════════════════════════════
class _RadiologyCard extends StatelessWidget {
  const _RadiologyCard({required this.image});
  final RadiologyImageModel image;

  @override
  Widget build(BuildContext context) {
    final imageUrl = '$_storageBaseUrl${image.imagePath}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: GestureDetector(
              onTap: () => _openFullScreenImage(context, imageUrl, image.title),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: AppColors.border,
                  child: const Center(
                    child: Icon(Icons.broken_image_rounded,
                        size: 48, color: AppColors.textSecondary),
                  ),
                ),
                loadingBuilder: (_, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: AppColors.border,
                    child: const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    ),
                  );
                },
              ),
            ),
          ),
          // Title + report
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  image.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                if (image.report.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    image.report,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(image.createdAt),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openFullScreenImage(
      BuildContext context, String url, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_rounded,
                      size: 64,
                      color: Colors.white54)),
            ),
          ),
        ),
      ),
    );
  }
}

class _TreatmentPlanCard extends StatelessWidget {
  const _TreatmentPlanCard({required this.plan});
  final TreatmentPlanModel plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.planContent,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 6),
          Text(
            _formatDateTime(plan.createdAt),
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}


class _MeasurementRow {
  const _MeasurementRow({
    required this.title,
    required this.value,
    required this.unit,
    required this.normalMin,
    required this.normalMax,
    required this.date,
  });

  final String title;
  final String value;
  final String unit;
  final String normalMin;
  final String normalMax;
  final String date;
}

class _MeasurementTable extends StatelessWidget {
  const _MeasurementTable({required this.records});
  final List<_MeasurementRow> records;

  Color _valueColor(_MeasurementRow r) {
    final val = double.tryParse(r.value);
    final min = double.tryParse(r.normalMin);
    final max = double.tryParse(r.normalMax);
    if (val == null || min == null || max == null) {
      return AppColors.textPrimary;
    }
    return (val >= min && val <= max) ? AppColors.success : AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(2),
      },
      children: [
        // Header
        const TableRow(
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1)),
          ),
          children: [
            _TableHeader('Title'),
            _TableHeader('Value'),
            _TableHeader('Unit'),
            _TableHeader('Normal'),
          ],
        ),
        // Data rows
        ...records.map((r) {
          final color = _valueColor(r);
          return TableRow(
            children: [
              _TableCell(r.title, fontWeight: FontWeight.w600),
              _TableCell(r.value, color: color, fontWeight: FontWeight.bold),
              _TableCell(r.unit),
              _TableCell('${r.normalMin} – ${r.normalMax}'),
            ],
          );
        }),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell(this.text,
      {this.color = AppColors.textPrimary,
      this.fontWeight = FontWeight.normal});
  final String text;
  final Color color;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}


class _KV {
  const _KV(this.key, this.value);
  final String key;
  final String value;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.icon, required this.title, required this.rows});
  final IconData icon;
  final String title;
  final List<_KV> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          ...rows.map(
            (kv) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 65,
                    child: Text(
                      kv.key,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      kv.value,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}


String _formatDate(String? raw) {
  if (raw == null || raw.isEmpty) return AppTexts.notAvailable;
  final t = raw.indexOf('T');
  return t > 0 ? raw.substring(0, t) : raw;
}

String _formatDateTime(String raw) {
  if (raw.isEmpty) return AppTexts.notAvailable;
  final t = raw.indexOf('T');
  if (t <= 0) return raw;
  final date = raw.substring(0, t);
  final time = raw.length > t + 1
      ? raw.substring(t + 1, raw.length > t + 9 ? t + 9 : raw.length)
      : '';
  return time.isEmpty ? date : '$date $time';
}
