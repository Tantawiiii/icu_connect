import 'package:flutter/services.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../superAdmin/patients/models/patient_admission_models.dart';
import '../models/admission_activity.dart';
import '../widgets/admission_details_formatters.dart';

class AdmissionPdfBuilder {
  AdmissionPdfBuilder._();

  static final _primary = PdfColor.fromHex('#1A1F36');
  static final _muted = PdfColor.fromHex('#8A8D9F');
  static final _border = PdfColor.fromHex('#E0E0E0');
  static final _surface = PdfColor.fromHex('#F5F6FA');
  static final _accent = PdfColor.fromHex('#4CAF50');

  static Future<Uint8List> build({
    required PatientAdmissionModel admission,
    List<AdmissionActivity> activities = const [],
  }) async {
    pw.ImageProvider? logo;
    try {
      final bytes = await rootBundle.load('assets/app_logo_without_back.png');
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}

    final doc = pw.Document(
      title: _documentTitle(admission),
      author: 'ICU Connect',
    );

    final generatedAt = DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 48),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        header: (context) => _pageHeader(
          admission: admission,
          logo: logo,
          pageNumber: context.pageNumber,
          pagesCount: context.pagesCount,
        ),
        footer: (context) => _pageFooter(context),
        build: (context) => [
          _heroSummary(admission, generatedAt),
          pw.SizedBox(height: 18),
          if (admission.patient != null) ...[
            _sectionTitle('Patient'),
            pw.SizedBox(height: 8),
            _infoCard(_patientRows(admission.patient!)),
            pw.SizedBox(height: 16),
          ],
          _sectionTitle('Admission'),
          pw.SizedBox(height: 8),
          _infoCard(_admissionRows(admission)),
          pw.SizedBox(height: 16),
          if (admission.doctor != null) ...[
            _sectionTitle('Attending doctor'),
            pw.SizedBox(height: 8),
            _infoCard(_doctorRows(admission)),
            pw.SizedBox(height: 16),
          ],
          if (admission.notes.trim().isNotEmpty) ...[
            _sectionTitle(AppTexts.admissionNotesSection),
            pw.SizedBox(height: 8),
            _textCard(admission.notes),
            pw.SizedBox(height: 16),
          ],
          ..._clinicalNotesSection(admission),
          ..._treatmentPlansSection(admission),
          ..._vitalsSection(admission),
          ..._labsSection(admission),
          ..._medicationsSection(admission),
          ..._radiologySection(admission),
          ..._simpleNotesSection('Echo', admission.echoes.map((e) => (e.text, e.createdAt)).toList()),
          ..._simpleNotesSection(
            'Ultrasound',
            admission.ultrasounds.map((u) => (u.text, u.createdAt)).toList(),
          ),
          ..._culturesSection(admission),
          ..._activitySection(activities),
        ],
      ),
    );

    return doc.save();
  }

  static String _documentTitle(PatientAdmissionModel admission) {
    final name = admission.patient?.name.trim();
    if (name != null && name.isNotEmpty) {
      return '$name — Admission #${admission.id}';
    }
    return 'Admission #${admission.id}';
  }

  static pw.Widget _pageHeader({
    required PatientAdmissionModel admission,
    required pw.ImageProvider? logo,
    required int pageNumber,
    required int pagesCount,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _border, width: 1),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null)
            pw.Container(
              height: 28,
              width: 28,
              margin: const pw.EdgeInsets.only(right: 10),
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ICU Connect',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _primary,
                  ),
                ),
                pw.Text(
                  admission.hospital?.name ?? 'Admission report',
                  style: pw.TextStyle(fontSize: 9, color: _muted),
                ),
              ],
            ),
          ),
          pw.Text(
            'Page $pageNumber of $pagesCount',
            style: pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pageFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Confidential medical record · ICU Connect',
        style: pw.TextStyle(fontSize: 8, color: _muted),
      ),
    );
  }

  static pw.Widget _heroSummary(
    PatientAdmissionModel admission,
    DateTime generatedAt,
  ) {
    final patient = admission.patient;
    final patientName = patient?.name.trim().isNotEmpty == true
        ? patient!.name
        : 'Admission #${admission.id}';
    final status = admission.status.isEmpty
        ? AppTexts.notAvailable
        : admission.status[0].toUpperCase() + admission.status.substring(1);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: _primary,
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            patientName,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              _heroChip('Bed ${admission.bedNumber.isEmpty ? '—' : admission.bedNumber}'),
              _heroChip(status),
              if (admission.hospitalGroup != null)
                _heroChip(admission.hospitalGroup!.name),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Generated ${_formatGeneratedAt(generatedAt)}',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromHex('#B8BBCC'),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _heroChip(String label) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#2A3150'),
        borderRadius: pw.BorderRadius.circular(999),
      ),
      child: pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: 16,
          decoration: pw.BoxDecoration(
            color: _accent,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: _primary,
          ),
        ),
      ],
    );
  }

  static pw.Widget _infoCard(List<(String, String)> rows) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _surface,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) pw.Divider(color: _border, height: 12),
            _infoRow(rows[i].$1, rows[i].$2),
          ],
        ],
      ),
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _muted,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value.isEmpty ? AppTexts.notAvailable : value,
            style: pw.TextStyle(fontSize: 10, color: _primary),
          ),
        ),
      ],
    );
  }

  static pw.Widget _textCard(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, color: _primary, lineSpacing: 1.4),
      ),
    );
  }

  static List<(String, String)> _patientRows(AdmissionPatientModel patient) {
    return [
      ('Name', patient.name),
      ('National ID', patient.nationalId),
      ('Age', patient.age > 0 ? '${patient.age}' : AppTexts.notAvailable),
      ('Gender', patient.gender),
      ('Blood group', patient.bloodGroup),
      ('Phone', patient.phone),
      if (patient.notes.trim().isNotEmpty) ('Notes', patient.notes),
    ];
  }

  static List<(String, String)> _admissionRows(PatientAdmissionModel admission) {
    return [
      ('Admission ID', '#${admission.id}'),
      ('Bed', admission.bedNumber),
      ('Status', admission.status),
      ('Admitted', admissionDetailsFormatDate(admission.dateComes)),
      ('Discharged', admissionDetailsFormatDate(admission.dateLeave)),
      if (admission.dateOfDeath != null && admission.dateOfDeath!.isNotEmpty)
        ('Date of death', admissionDetailsFormatDate(admission.dateOfDeath)),
      if (admission.hospitalGroup != null)
        ('Ward / group', admission.hospitalGroup!.name),
      if (admission.hospital != null) ('Hospital', admission.hospital!.name),
    ];
  }

  static List<(String, String)> _doctorRows(PatientAdmissionModel admission) {
    final doctor = admission.doctor!;
    return [
      ('Name', doctor.name),
      ('Email', doctor.email),
      ('Phone', doctor.phone),
    ];
  }

  static List<pw.Widget> _clinicalNotesSection(PatientAdmissionModel admission) {
    if (admission.clinicalNotes.isEmpty) return [];
    return [
      _sectionTitle('Clinical notes'),
      pw.SizedBox(height: 8),
      ...admission.clinicalNotes.map(
        (n) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: _recordCard(
            title: n.type.replaceAll('_', ' '),
            subtitle: admissionDetailsFormatDateTime(n.createdAt),
            body: n.content,
          ),
        ),
      ),
      pw.SizedBox(height: 8),
    ];
  }

  static List<pw.Widget> _treatmentPlansSection(
    PatientAdmissionModel admission,
  ) {
    if (admission.treatmentPlans.isEmpty) return [];
    return [
      _sectionTitle('Treatment plans'),
      pw.SizedBox(height: 8),
      ...admission.treatmentPlans.map(
        (p) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: _recordCard(
            title: 'Plan',
            subtitle: admissionDetailsFormatDateTime(p.createdAt),
            body: p.planContent,
          ),
        ),
      ),
      pw.SizedBox(height: 8),
    ];
  }

  static List<pw.Widget> _vitalsSection(PatientAdmissionModel admission) {
    if (admission.vitals.isEmpty) return [];
    return [
      _sectionTitle(AppTexts.vitalSigns),
      pw.SizedBox(height: 8),
      _measurementTable(
        headers: const ['Vital', 'Value', 'Date'],
        rows: admission.vitals.map((v) {
          final title = v.vitalsTitle?.title ?? 'Vital #${v.vitalsTitleId}';
          final unit = v.vitalsTitle?.unit ?? '';
          final value = unit.isEmpty ? v.value : '${v.value} $unit';
          return [title, value, admissionDetailsFormatDateTime(v.date)];
        }).toList(),
      ),
      pw.SizedBox(height: 16),
    ];
  }

  static List<pw.Widget> _labsSection(PatientAdmissionModel admission) {
    if (admission.labs.isEmpty) return [];
    return [
      _sectionTitle(AppTexts.labs),
      pw.SizedBox(height: 8),
      _measurementTable(
        headers: const ['Lab', 'Result', 'Date'],
        rows: admission.labs.map((l) {
          final title = l.labsTitle?.title ?? 'Lab #${l.labsTitleId}';
          final unit = l.labsTitle?.unit ?? '';
          final value = unit.isEmpty ? l.value : '${l.value} $unit';
          return [title, value, admissionDetailsFormatDateTime(l.date)];
        }).toList(),
      ),
      pw.SizedBox(height: 16),
    ];
  }

  static List<pw.Widget> _medicationsSection(PatientAdmissionModel admission) {
    if (admission.medications.isEmpty) return [];
    return [
      _sectionTitle('Medications'),
      pw.SizedBox(height: 8),
      _measurementTable(
        headers: const ['Medication', 'Details', 'Recorded'],
        rows: admission.medications.map((m) {
          final details = [
            if (m.type.isNotEmpty) m.type,
            if (m.value.isNotEmpty) m.value,
            if (m.duration.isNotEmpty) m.duration,
          ].join(' · ');
          return [
            m.title,
            details.isEmpty ? AppTexts.notAvailable : details,
            admissionDetailsFormatDateTime(m.createdAt),
          ];
        }).toList(),
      ),
      pw.SizedBox(height: 16),
    ];
  }

  static List<pw.Widget> _radiologySection(PatientAdmissionModel admission) {
    if (admission.radiologyImages.isEmpty) return [];
    return [
      _sectionTitle('Radiology'),
      pw.SizedBox(height: 8),
      ...admission.radiologyImages.map(
        (r) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: _recordCard(
            title: r.title,
            subtitle: admissionDetailsFormatDateTime(r.createdAt),
            body: r.report.isEmpty ? 'Image on file' : r.report,
          ),
        ),
      ),
      pw.SizedBox(height: 8),
    ];
  }

  static List<pw.Widget> _culturesSection(PatientAdmissionModel admission) {
    if (admission.cultures.isEmpty) return [];
    return [
      _sectionTitle('Cultures'),
      pw.SizedBox(height: 8),
      ...admission.cultures.map(
        (c) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: _recordCard(
            title: c.title,
            subtitle: admissionDetailsFormatDateTime(c.createdAt),
            body: c.note.isEmpty ? AppTexts.notAvailable : c.note,
          ),
        ),
      ),
      pw.SizedBox(height: 8),
    ];
  }

  static List<pw.Widget> _simpleNotesSection(
    String title,
    List<(String text, String date)> items,
  ) {
    if (items.isEmpty) return [];
    return [
      _sectionTitle(title),
      pw.SizedBox(height: 8),
      ...items.map(
        (item) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: _recordCard(
            title: title,
            subtitle: admissionDetailsFormatDateTime(item.$2),
            body: item.$1,
          ),
        ),
      ),
      pw.SizedBox(height: 8),
    ];
  }

  static List<pw.Widget> _activitySection(List<AdmissionActivity> activities) {
    if (activities.isEmpty) return [];
    return [
      _sectionTitle(AppTexts.activityHistorySection),
      pw.SizedBox(height: 8),
      ...activities.take(50).map(
        (a) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _border),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      a.subjectTypeEnum?.label ?? a.subjectType,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: _primary,
                      ),
                    ),
                    pw.Text(
                      admissionDetailsFormatDateTime(a.createdAt),
                      style: pw.TextStyle(fontSize: 8, color: _muted),
                    ),
                  ],
                ),
                if (a.description.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    a.description,
                    style: pw.TextStyle(fontSize: 9, color: _primary),
                  ),
                ],
                if (a.actorName != null && a.actorName!.isNotEmpty) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'By ${a.actorName}',
                    style: pw.TextStyle(fontSize: 8, color: _muted),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ];
  }

  static pw.Widget _recordCard({
    required String title,
    required String subtitle,
    required String body,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _primary,
                ),
              ),
              pw.Text(
                subtitle,
                style: pw.TextStyle(fontSize: 8, color: _muted),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            body,
            style: pw.TextStyle(fontSize: 10, color: _primary, lineSpacing: 1.35),
          ),
        ],
      ),
    );
  }

  static pw.Widget _measurementTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _primary),
          children: headers
              .map(
                (h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    h,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        ...rows.map(
          (row) => pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.white),
            children: row
                .map(
                  (cell) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      cell.isEmpty ? AppTexts.notAvailable : cell,
                      style: pw.TextStyle(fontSize: 9, color: _primary),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  static String _formatGeneratedAt(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }
}
