import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/features/superAdmin/patients/models/patient_admission_models.dart';

import 'admission_details_formatters.dart';
import 'admission_details_section_container.dart';
import 'pending_measurement_entry.dart';

class AdmissionDetailsMeasurementSection extends StatelessWidget {
  const AdmissionDetailsMeasurementSection({
    super.key,
    required this.title,
    required this.isLabs,
    required this.records,
    required this.titles,
    required this.adding,
    required this.saving,
    required this.pending,
    required this.onStartAdd,
    required this.onCancelAdd,
    required this.onSaveAdd,
    required this.onPickDate,
  });

  final String title;
  final bool isLabs;
  final List<dynamic> records;
  final List<MeasurementTitleModel> titles;
  final bool adding;
  final bool saving;
  final PendingMeasurementEntry? pending;
  final void Function([int? titleId]) onStartAdd;
  final VoidCallback onCancelAdd;
  final VoidCallback onSaveAdd;
  final VoidCallback onPickDate;

  Color _valueColor(String valueStr, String minStr, String maxStr) {
    final val = double.tryParse(valueStr);
    final min = double.tryParse(minStr);
    final max = double.tryParse(maxStr);
    if (val == null || min == null || max == null) return AppColors.textPrimary;
    return (val >= min && val <= max) ? AppColors.success : AppColors.error;
  }

  DateTime _recordDateTime(dynamic r) {
    try {
      if (isLabs) {
        final m = r as LabRecordModel;
        final raw = m.date.isNotEmpty ? m.date : m.createdAt;
        return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
      }
      final m = r as VitalRecordModel;
      final raw = m.date.isNotEmpty ? m.date : m.createdAt;
      return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  String _recordTimeLabel(dynamic r) {
    try {
      if (isLabs) {
        final m = r as LabRecordModel;
        final raw = m.date.isNotEmpty ? m.date : m.createdAt;
        return admissionDetailsFormatDateTime(raw);
      }
      final m = r as VitalRecordModel;
      final raw = m.date.isNotEmpty ? m.date : m.createdAt;
      return admissionDetailsFormatDateTime(raw);
    } catch (_) {
      return '—';
    }
  }

  List<dynamic> _recordsForTitle(int titleId) {
    try {
      final matches = records
          .where(
            (r) => (isLabs ? r.labsTitleId : r.vitalsTitleId) == titleId,
          )
          .toList();
      matches.sort((a, b) => _recordDateTime(b).compareTo(_recordDateTime(a)));
      return matches;
    } catch (_) {
      return [];
    }
  }

  static const double _kTitleWidth = 76;
  static const double _kRangeWidth = 100;
  static const double _kActionWidth = 44;
  static const double _kRowMinHeight = 52;
  /// Approximate width of one reading chip + spacing (see [_ReadingChip] maxWidth).
  static const double _kChipUnitWidth = 126;
  static const double _kPendingBlockWidth = 270;
  static const double _kReadingsMinWidth = 108;
  /// Extra px so layout rarely underestimates real chip / pending widths.
  static const double _kReadingsEstimatePadding = 40;

  double _estimateReadingsColumnWidth(int titleId) {
    final rowRecords = _recordsForTitle(titleId);
    final isAddingThis = adding && pending?.titleId == titleId;

    if (rowRecords.isEmpty && !isAddingThis) {
      return _kReadingsMinWidth;
    }

    double w = 0;
    if (isAddingThis) {
      w += _kPendingBlockWidth;
    }
    for (var i = 0; i < rowRecords.length; i++) {
      if (i > 0 || isAddingThis) {
        w += 6;
      }
      w += _kChipUnitWidth;
    }
    return math.max(_kReadingsMinWidth, w) + _kReadingsEstimatePadding;
  }

  double _maxReadingsColumnWidth() {
    if (titles.isEmpty) return _kReadingsMinWidth;
    return titles
        .map((t) => _estimateReadingsColumnWidth(t.id))
        .fold<double>(_kReadingsMinWidth, math.max);
  }

  @override
  Widget build(BuildContext context) {
    return AdmissionDetailsSectionContainer(
      title: title,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final readingsW = _maxReadingsColumnWidth();
          final tableInnerWidth =
              _kTitleWidth + readingsW + _kRangeWidth + _kActionWidth;
          final viewportW = constraints.maxWidth;
          final contentW = viewportW.isFinite && viewportW > 0
              ? math.max(viewportW, tableInnerWidth)
              : tableInnerWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: contentW,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MeasurementHeaderRow(
                    titleWidth: _kTitleWidth,
                    readingsWidth: readingsW,
                    rangeWidth: _kRangeWidth,
                    actionWidth: _kActionWidth,
                  ),
                  const Divider(height: 1),
                  ...titles.map((measureTitle) {
                    final rowRecords = _recordsForTitle(measureTitle.id);
                    final isAddingThis =
                        adding && pending?.titleId == measureTitle.id;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: _kTitleWidth,
                                child: Text(
                                  measureTitle.title.toUpperCase(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: readingsW,
                                height: _kRowMinHeight,
                                child: ClipRect(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      physics: const ClampingScrollPhysics(),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          if (isAddingThis)
                                            _PendingInline(
                                              pending: pending!,
                                              saving: saving,
                                              onPickDate: onPickDate,
                                              onSaveAdd: onSaveAdd,
                                              onCancelAdd: onCancelAdd,
                                            ),
                                          if (rowRecords.isEmpty && !isAddingThis)
                                            const Padding(
                                              padding: EdgeInsets.only(left: 4),
                                              child: Text(
                                                '—',
                                                style: TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            )
                                          else
                                            ...rowRecords.map(
                                              (record) => Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 6,
                                                ),
                                                child: _ReadingChip(
                                                  measureTitle: measureTitle,
                                                  record: record,
                                                  isLabs: isLabs,
                                                  valueColor: _valueColor(
                                                    isLabs
                                                        ? (record
                                                                as LabRecordModel)
                                                            .value
                                                        : (record
                                                                as VitalRecordModel)
                                                            .value,
                                                    measureTitle.normalRangeMin,
                                                    measureTitle.normalRangeMax,
                                                  ),
                                                  timeLabel:
                                                      _recordTimeLabel(record),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: _kRangeWidth,
                                child: Text(
                                  '${measureTitle.normalRangeMin}–${measureTitle.normalRangeMax}',
                                  textAlign: TextAlign.end,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: _kActionWidth,
                                child: isAddingThis
                                    ? const SizedBox.shrink()
                                    : IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: _kActionWidth,
                                          minHeight: _kActionWidth,
                                        ),
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                          color: AppColors.primary,
                                          size: 22,
                                        ),
                                        onPressed: () =>
                                            onStartAdd(measureTitle.id),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                      ],
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MeasurementHeaderRow extends StatelessWidget {
  const _MeasurementHeaderRow({
    required this.titleWidth,
    required this.readingsWidth,
    required this.rangeWidth,
    required this.actionWidth,
  });

  final double titleWidth;
  final double readingsWidth;
  final double rangeWidth;
  final double actionWidth;

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: titleWidth,
            child: const Text('Title', style: labelStyle),
          ),
          SizedBox(
            width: readingsWidth,
            child: const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'Reading',
                style: labelStyle,
              ),
            ),
          ),
          SizedBox(
            width: rangeWidth,
            child: const Text(
              'Range',
              textAlign: TextAlign.end,
              style: labelStyle,
            ),
          ),
          SizedBox(
            width: actionWidth,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ReadingChip extends StatelessWidget {
  const _ReadingChip({
    required this.measureTitle,
    required this.record,
    required this.isLabs,
    required this.valueColor,
    required this.timeLabel,
  });

  final MeasurementTitleModel measureTitle;
  final dynamic record;
  final bool isLabs;
  final Color valueColor;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final value = isLabs
        ? (record as LabRecordModel).value
        : (record as VitalRecordModel).value;
    return Container(
      constraints: const BoxConstraints(minWidth: 72, maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value ${measureTitle.unit}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            timeLabel,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingInline extends StatelessWidget {
  const _PendingInline({
    required this.pending,
    required this.saving,
    required this.onPickDate,
    required this.onSaveAdd,
    required this.onCancelAdd,
  });

  final PendingMeasurementEntry pending;
  final bool saving;
  final VoidCallback onPickDate;
  final VoidCallback onSaveAdd;
  final VoidCallback onCancelAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 64,
            child: TextField(
              controller: pending.valueCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '0.0',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onPickDate,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.edit_calendar,
                  size: 16,
                  color: AppColors.primary,
                ),
                Text(
                  admissionDetailsFormatDateTime(
                    pending.date.toIso8601String(),
                  ),
                  style: const TextStyle(fontSize: 8),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          if (saving)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 22,
              ),
              onPressed: onSaveAdd,
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.cancel,
                color: AppColors.error,
                size: 22,
              ),
              onPressed: onCancelAdd,
            ),
          ],
        ],
      ),
    );
  }
}
