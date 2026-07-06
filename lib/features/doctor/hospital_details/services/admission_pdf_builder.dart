import 'package:flutter/services.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../superAdmin/patients/models/patient_admission_models.dart';
import '../widgets/admission_details_formatters.dart';

class AdmissionPdfBuilder {
  AdmissionPdfBuilder._();

  static Future<Uint8List> build({
    required PatientAdmissionModel admission,
  }) {
    return _AdmissionPdfRenderer(admission: admission).render();
  }
}

/// A single measurement reading, flattened for the transposed matrix table.
class _MeasureEntry {
  const _MeasureEntry({
    required this.titleId,
    required this.title,
    required this.unit,
    required this.rangeMin,
    required this.rangeMax,
    required this.value,
    required this.dayKey,
  });

  final int titleId;
  final String title;
  final String unit;
  final String rangeMin;
  final String rangeMax;
  final String value;
  final String dayKey; // yyyy-MM-dd
}

class _PdfFonts {
  const _PdfFonts({
    required this.base,
    required this.bold,
    required this.arabic,
    required this.arabicBold,
  });

  final pw.Font base;
  final pw.Font bold;
  final pw.Font arabic;
  final pw.Font arabicBold;

  static Future<_PdfFonts> load() async {
    Future<pw.Font> loadFont(String asset) async {
      final data = await rootBundle.load(asset);
      return pw.Font.ttf(data);
    }

    return _PdfFonts(
      base: await loadFont('assets/fonts/OpenSans-Regular.ttf'),
      bold: await loadFont('assets/fonts/OpenSans-Bold.ttf'),
      arabic: await loadFont('assets/fonts/NotoNaskhArabic-Regular.ttf'),
      arabicBold: await loadFont('assets/fonts/NotoNaskhArabic-Bold.ttf'),
    );
  }

  pw.ThemeData get theme => pw.ThemeData.withFont(
        base: base,
        bold: bold,
        fontFallback: [arabic],
      );
}

final _arabicScript = RegExp(
  r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
);

bool _containsArabic(String text) => _arabicScript.hasMatch(text);

class _AdmissionPdfRenderer {
  _AdmissionPdfRenderer({
    required this.admission,
  });

  final PatientAdmissionModel admission;

  static final _primary = PdfColor.fromHex('#1A1F36');
  static final _muted = PdfColor.fromHex('#8A8D9F');
  static final _border = PdfColor.fromHex('#E8EAEF');
  static final _surface = PdfColor.fromHex('#F5F7FB');
  static final _accent = PdfColor.fromHex('#4CAF50');
  static final _heroMuted = PdfColor.fromHex('#B8BBCC');
  static final _abnormal = PdfColor.fromHex('#C62828');
  static final _abnormalSoft = PdfColor.fromHex('#FDECEA');

  late final _PdfFonts _fonts;

  Future<Uint8List> render() async {
    _fonts = await _PdfFonts.load();

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
          margin: const pw.EdgeInsets.fromLTRB(18, 18, 18, 26),
          theme: _fonts.theme,
        ),
        header: (context) => _pageHeader(
          logo: logo,
          pageNumber: context.pageNumber,
          pagesCount: context.pagesCount,
        ),
        footer: (context) => _pageFooter(),
        build: (context) => [
          _heroSummary(generatedAt),
          pw.SizedBox(height: 12),
          if (admission.patient != null) ...[
            _sectionTitle('Patient'),
            pw.SizedBox(height: 6),
            _infoCard(_patientRows(admission.patient!)),
            pw.SizedBox(height: 10),
          ],
          _sectionTitle('Admission'),
          pw.SizedBox(height: 6),
          _infoCard(_admissionRows(admission)),
          pw.SizedBox(height: 10),
          if (admission.doctor != null) ...[
            _sectionTitle('Attending doctor'),
            pw.SizedBox(height: 6),
            _infoCard(_doctorRows(admission)),
            pw.SizedBox(height: 10),
          ],
          if (admission.notes.trim().isNotEmpty) ...[
            _sectionTitle(AppTexts.admissionNotesSection),
            pw.SizedBox(height: 6),
            _textCard(admission.notes),
            pw.SizedBox(height: 10),
          ],
          ..._clinicalNotesSection(),
          ..._treatmentPlansSection(),
          ..._vitalsSection(),
          ..._labsSection(),
          ..._medicationsSection(),
          ..._radiologySection(),
          ..._simpleNotesSection(
            'Echo',
            admission.echoes.map((e) => (e.text, e.createdAt)).toList(),
          ),
          ..._simpleNotesSection(
            'Ultrasound',
            admission.ultrasounds.map((u) => (u.text, u.createdAt)).toList(),
          ),
          ..._culturesSection(),
        ],
      ),
    );

    return doc.save();
  }

  pw.TextStyle _style({
    double fontSize = 10,
    PdfColor? color,
    bool bold = false,
    double? lineSpacing,
  }) {
    return pw.TextStyle(
      fontSize: fontSize,
      color: color ?? _primary,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      lineSpacing: lineSpacing,
      fontFallback: bold ? [_fonts.arabicBold] : [_fonts.arabic],
    );
  }

  pw.Widget _txt(
    String text, {
    pw.TextStyle? style,
    pw.TextAlign? textAlign,
  }) {
    final rtl = _containsArabic(text);
    // Arabic only joins/shapes correctly when the Arabic font is the PRIMARY
    // font. Via fontFallback each glyph is drawn in isolation (disconnected,
    // out-of-order letters), so promote the Arabic font for RTL strings.
    var effectiveStyle = style;
    if (rtl) {
      final isBold = style?.fontWeight == pw.FontWeight.bold;
      final arabicFont = isBold ? _fonts.arabicBold : _fonts.arabic;
      effectiveStyle = (style ?? _style()).copyWith(
        font: arabicFont,
        fontNormal: arabicFont,
        fontBold: _fonts.arabicBold,
        fontFallback: [arabicFont],
      );
    }
    return pw.Text(
      text,
      style: effectiveStyle,
      textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      textAlign: textAlign ?? (rtl ? pw.TextAlign.right : pw.TextAlign.left),
    );
  }

  String _documentTitle(PatientAdmissionModel admission) {
    final name = admission.patient?.name.trim();
    if (name != null && name.isNotEmpty) {
      return '$name — Admission #${admission.id}';
    }
    return 'Admission #${admission.id}';
  }

  pw.Widget _pageHeader({
    required pw.ImageProvider? logo,
    required int pageNumber,
    required int pagesCount,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.only(bottom: 12),
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
              height: 32,
              width: 32,
              margin: const pw.EdgeInsets.only(right: 12),
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _txt(
                  'ICU Connect',
                  style: _style(fontSize: 12, bold: true, color: _primary),
                ),
                pw.SizedBox(height: 2),
                _txt(
                  admission.hospital?.name ?? 'Admission report',
                  style: _style(fontSize: 9, color: _muted),
                ),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: pw.BoxDecoration(
              color: _surface,
              borderRadius: pw.BorderRadius.circular(999),
            ),
            child: _txt(
              'Page $pageNumber / $pagesCount',
              style: _style(fontSize: 8, color: _muted),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pageFooter() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _border, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _txt(
            'Confidential medical record',
            style: _style(fontSize: 8, color: _muted),
          ),
          _txt(
            'ICU Connect',
            style: _style(fontSize: 8, bold: true, color: _accent),
          ),
        ],
      ),
    );
  }

  pw.Widget _heroSummary(DateTime generatedAt) {
    final patient = admission.patient;
    final patientName = patient?.name.trim().isNotEmpty == true
        ? patient!.name
        : 'Admission #${admission.id}';
    final status = admission.status.isEmpty
        ? AppTexts.notAvailable
        : admissionStatusDisplayLabel(admission.status);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: pw.BoxDecoration(
        color: _primary,
        borderRadius: pw.BorderRadius.circular(16),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _txt(
                  patientName,
                  style: _style(
                    fontSize: 22,
                    bold: true,
                    color: PdfColors.white,
                  ),
                ),
              ),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: _accent,
                  borderRadius: pw.BorderRadius.circular(999),
                ),
                child: _txt(
                  status,
                  style: _style(
                    fontSize: 9,
                    bold: true,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _heroChip(
                'Bed ${admission.bedNumber.isEmpty ? '—' : admission.bedNumber}',
              ),
              if (admission.hospitalGroup != null)
                _heroChip(admission.hospitalGroup!.name),
              if (admission.hospital != null) _heroChip(admission.hospital!.name),
            ],
          ),
          pw.SizedBox(height: 12),
          _txt(
            'Generated ${_formatGeneratedAt(generatedAt)}',
            style: _style(fontSize: 9, color: _heroMuted),
          ),
        ],
      ),
    );
  }

  pw.Widget _heroChip(String label) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#2A3150'),
        borderRadius: pw.BorderRadius.circular(999),
      ),
      child: _txt(
        label,
        style: _style(fontSize: 9, color: PdfColors.white),
      ),
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: 18,
          decoration: pw.BoxDecoration(
            color: _accent,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 10),
        _txt(
          title,
          style: _style(fontSize: 14, bold: true, color: _primary),
        ),
      ],
    );
  }

  pw.Widget _infoCard(List<(String, String)> rows) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: pw.BoxDecoration(
        color: _surface,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) pw.Divider(color: _border, height: 1),
            _infoRow(rows[i].$1, rows[i].$2),
          ],
        ],
      ),
    );
  }

  pw.Widget _infoRow(String label, String value) {
    final display = value.isEmpty ? AppTexts.notAvailable : value;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 118,
            child: _txt(
              label,
              style: _style(fontSize: 9, bold: true, color: _muted),
            ),
          ),
          pw.Expanded(
            child: _txt(
              display,
              style: _style(fontSize: 10, color: _primary),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _textCard(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 3,
            height: 36,
            margin: const pw.EdgeInsets.only(right: 12),
            decoration: pw.BoxDecoration(
              color: _accent,
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
          pw.Expanded(
            child: _txt(
              text,
              style: _style(fontSize: 10, color: _primary, lineSpacing: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  List<(String, String)> _patientRows(AdmissionPatientModel patient) {
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

  List<(String, String)> _admissionRows(PatientAdmissionModel admission) {
    return [
      ('Admission ID', '#${admission.id}'),
      ('Bed', admission.bedNumber),
      ('Status', admissionStatusDisplayLabel(admission.status)),
      ('Admitted', admissionDetailsFormatDate(admission.dateComes)),
      ('Discharged', admissionDetailsFormatDate(admission.dateLeave)),
      if (admission.dateOfDeath != null && admission.dateOfDeath!.isNotEmpty)
        ('Date of death', admissionDetailsFormatDate(admission.dateOfDeath)),
      if (admission.hospitalGroup != null)
        ('Ward / group', admission.hospitalGroup!.name),
      if (admission.hospital != null) ('Hospital', admission.hospital!.name),
    ];
  }

  List<(String, String)> _doctorRows(PatientAdmissionModel admission) {
    final doctor = admission.doctor!;
    return [
      ('Name', doctor.name),
      ('Email', doctor.email),
      ('Phone', doctor.phone),
    ];
  }

  List<pw.Widget> _clinicalNotesSection() {
    if (admission.clinicalNotes.isEmpty) return [];
    return [
      _sectionTitle(AppTexts.clinicalNotesSection),
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
      pw.SizedBox(height: 10),
    ];
  }

  List<pw.Widget> _treatmentPlansSection() {
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
      pw.SizedBox(height: 10),
    ];
  }

  List<pw.Widget> _vitalsSection() {
    final entries = admission.vitals
        .map(
          (v) => _MeasureEntry(
            titleId: v.vitalsTitleId,
            title: v.vitalsTitle?.title ?? 'Vital #${v.vitalsTitleId}',
            unit: v.vitalsTitle?.unit ?? '',
            rangeMin: v.vitalsTitle?.normalRangeMin ?? '',
            rangeMax: v.vitalsTitle?.normalRangeMax ?? '',
            value: v.value,
            dayKey: v.date.isNotEmpty ? v.date : v.createdAt,
          ),
        )
        .toList();
    return _readingsSection(AppTexts.vitalSigns, entries);
  }

  List<pw.Widget> _labsSection() {
    final entries = admission.labs
        .map(
          (l) => _MeasureEntry(
            titleId: l.labsTitleId,
            title: l.labsTitle?.title ?? 'Lab #${l.labsTitleId}',
            unit: l.labsTitle?.unit ?? '',
            rangeMin: l.labsTitle?.normalRangeMin ?? '',
            rangeMax: l.labsTitle?.normalRangeMax ?? '',
            value: l.value,
            dayKey: l.date.isNotEmpty ? l.date : l.createdAt,
          ),
        )
        .toList();
    return _readingsSection(AppTexts.labs, entries);
  }

  bool _isAbnormal(_MeasureEntry rep, String value) {
    final v = double.tryParse(value);
    if (v == null) return false;
    final min = double.tryParse(rep.rangeMin);
    final max = double.tryParse(rep.rangeMax);
    if (min != null && v < min) return true;
    if (max != null && v > max) return true;
    return false;
  }

  /// One table per title: the title as a heading, then a Date | Reading table
  /// with a row for every reading of that title (newest first). Out-of-range
  /// values are flagged in red.
  List<pw.Widget> _readingsSection(String title, List<_MeasureEntry> entries) {
    if (entries.isEmpty) return [];

    // Group readings by their title, keeping first-seen order.
    final order = <int>[];
    final grouped = <int, List<_MeasureEntry>>{};
    for (final e in entries) {
      if (!grouped.containsKey(e.titleId)) order.add(e.titleId);
      (grouped[e.titleId] ??= []).add(e);
    }

    final hasAbnormal = entries.any((e) => _isAbnormal(e, e.value));

    return [
      _sectionTitle(title),
      pw.SizedBox(height: 8),
      ...order.map((id) {
        final group = [...grouped[id]!]
          ..sort((a, b) => b.dayKey.compareTo(a.dayKey));
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: _titleReadingsTable(group),
        );
      }),
      if (hasAbnormal)
        _txt(
          '* value outside the normal range',
          style: _style(fontSize: 8, color: _abnormal),
        ),
      pw.SizedBox(height: 10),
    ];
  }

  pw.Widget _titleReadingsTable(List<_MeasureEntry> readings) {
    final rep = readings.first;
    final heading = rep.unit.isEmpty ? rep.title : '${rep.title} (${rep.unit})';

    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _border),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 12,
        verticalRadius: 12,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Title heading spanning the whole card.
            pw.Container(
              width: double.infinity,
              color: _surface,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              child: _txt(
                heading,
                style: _style(fontSize: 10, bold: true, color: _primary),
              ),
            ),
            pw.Table(
              border: pw.TableBorder(
                horizontalInside: pw.BorderSide(color: _border, width: 0.5),
                verticalInside: pw.BorderSide(color: _border, width: 0.5),
                top: pw.BorderSide(color: _border, width: 0.5),
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: _primary),
                  children: [
                    _readingCell('Date', bold: true, color: PdfColors.white),
                    _readingCell('Reading', bold: true, color: PdfColors.white),
                  ],
                ),
                ...readings.asMap().entries.map((row) {
                  final e = row.value;
                  final abnormal = _isAbnormal(e, e.value);
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: abnormal
                          ? _abnormalSoft
                          : (row.key.isEven ? PdfColors.white : _surface),
                    ),
                    children: [
                      _readingCell(
                        admissionDetailsFormatDateTime(e.dayKey),
                        color: _muted,
                      ),
                      _readingCell(
                        abnormal ? '${e.value} *' : e.value,
                        bold: abnormal,
                        color: abnormal ? _abnormal : _primary,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _readingCell(
    String text, {
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: _txt(
        text.isEmpty ? AppTexts.notAvailable : text,
        style: _style(fontSize: 9, bold: bold, color: color ?? _primary),
      ),
    );
  }

  List<pw.Widget> _medicationsSection() {
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
      pw.SizedBox(height: 10),
    ];
  }

  List<pw.Widget> _radiologySection() {
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
      pw.SizedBox(height: 10),
    ];
  }

  List<pw.Widget> _culturesSection() {
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
      pw.SizedBox(height: 10),
    ];
  }

  List<pw.Widget> _simpleNotesSection(
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
      pw.SizedBox(height: 10),
    ];
  }

  pw.Widget _recordCard({
    required String title,
    required String subtitle,
    required String body,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 3,
            margin: const pw.EdgeInsets.only(right: 12, top: 2),
            decoration: pw.BoxDecoration(
              color: _accent,
              borderRadius: pw.BorderRadius.circular(2),
            ),
            child: pw.SizedBox(height: 40),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: _txt(
                        title,
                        style: _style(fontSize: 10, bold: true, color: _primary),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    _txt(
                      subtitle,
                      style: _style(fontSize: 8, color: _muted),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                _txt(
                  body,
                  style: _style(
                    fontSize: 10,
                    color: _primary,
                    lineSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _measurementTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _border),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 12,
        verticalRadius: 12,
        child: pw.Table(
          border: pw.TableBorder(
            horizontalInside: pw.BorderSide(color: _border, width: 0.5),
            verticalInside: pw.BorderSide(color: _border, width: 0.5),
          ),
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
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      child: _txt(
                        h,
                        style: _style(
                          fontSize: 9,
                          bold: true,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            ...rows.asMap().entries.map(
              (entry) {
                final isEven = entry.key.isEven;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: isEven ? PdfColors.white : _surface,
                  ),
                  children: entry.value
                      .map(
                        (cell) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          child: _txt(
                            cell.isEmpty ? AppTexts.notAvailable : cell,
                            style: _style(fontSize: 9, color: _primary),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatGeneratedAt(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }
}
