import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/features/superAdmin/patients/models/patient_admission_models.dart';

import 'admission_details_formatters.dart';
import 'admission_details_section_container.dart';
import 'pending_measurement_column_entry.dart';

String _measurementRangeLabel(MeasurementTitleModel title) {
  final min = title.normalRangeMin.trim();
  final max = title.normalRangeMax.trim();
  if (min.isEmpty && max.isEmpty) return '—';
  return '$min–$max';
}

class AdmissionDetailsMeasurementSection extends StatelessWidget {
  const AdmissionDetailsMeasurementSection({
    super.key,
    required this.title,
    required this.isLabs,
    required this.records,
    required this.titles,
    required this.addingColumn,
    required this.saving,
    required this.pendingColumn,
    required this.onStartAddColumn,
    required this.onCancelAddColumn,
    required this.onSaveColumn,
    required this.onPickColumnDate,
    required this.onEditColumn,
    this.onAddTitle,
    this.addingTitle = false,
  });

  final String title;
  final bool isLabs;
  final List<dynamic> records;
  final List<MeasurementTitleModel> titles;
  final bool addingColumn;
  final bool saving;
  final PendingMeasurementColumnEntry? pendingColumn;
  final VoidCallback onStartAddColumn;
  final VoidCallback onCancelAddColumn;
  final VoidCallback onSaveColumn;
  final VoidCallback onPickColumnDate;
  final void Function(String columnKey) onEditColumn;
  final VoidCallback? onAddTitle;
  final bool addingTitle;

  static const _titleWidth = 80.0;
  static const _rangeWidth = 76.0;
  static const _readingWidth = 100.0;
  static const _headerHeight = 40.0;
  static const _dateHeaderHeight = 52.0;
  static const _rowHeight = 44.0;

  String _columnKey(dynamic record) {
    if (isLabs) {
      final m = record as LabRecordModel;
      return m.date.isNotEmpty ? m.date : m.createdAt;
    }
    final m = record as VitalRecordModel;
    return m.date.isNotEmpty ? m.date : m.createdAt;
  }

  DateTime _parseColumnDate(String key) {
    return DateTime.tryParse(key) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _columnDateLabel(String key) {
    return admissionDetailsFormatDateTime(key);
  }

  List<String> _sortedColumnKeys() {
    final keys = <String>{};
    for (final r in records) {
      final key = _columnKey(r);
      if (key.isNotEmpty) keys.add(key);
    }
    final sorted = keys.toList()
      ..sort((a, b) => _parseColumnDate(a).compareTo(_parseColumnDate(b)));
    return sorted;
  }

  dynamic _recordAt(int titleId, String columnKey) {
    for (final r in records) {
      final tid = isLabs
          ? (r as LabRecordModel).labsTitleId
          : (r as VitalRecordModel).vitalsTitleId;
      if (tid == titleId && _columnKey(r) == columnKey) return r;
    }
    return null;
  }

  Color _valueColor(String valueStr, MeasurementTitleModel measureTitle) {
    if (!measureTitle.isNumericValueType) return AppColors.textPrimary;
    final val = double.tryParse(valueStr);
    final min = double.tryParse(measureTitle.normalRangeMin);
    final max = double.tryParse(measureTitle.normalRangeMax);
    if (val == null || min == null || max == null) return AppColors.textPrimary;
    return (val >= min && val <= max) ? AppColors.success : AppColors.error;
  }

  String _recordValue(dynamic record, MeasurementTitleModel measureTitle) {
    if (record == null) return '—';
    final value = isLabs
        ? (record as LabRecordModel).value
        : (record as VitalRecordModel).value;
    if (value.isEmpty) return '—';
    final unit = measureTitle.unit.trim();
    return unit.isEmpty ? value : '$value $unit';
  }

  Widget _buildReadingColumn(String key) {
    final isEditingInPlace =
        addingColumn && pendingColumn?.editingColumnKey == key;

    if (isEditingInPlace && pendingColumn != null) {
      return _EditingReadingColumn(
        pending: pendingColumn!,
        titles: titles,
        width: _readingWidth,
        dateHeaderHeight: _dateHeaderHeight,
        rowHeight: _rowHeight,
        saving: saving,
        onPickDate: onPickColumnDate,
        showAddTitleRow: onAddTitle != null,
        isLabs: isLabs,
      );
    }

    return _ReadingColumn(
      columnKey: key,
      dateLabel: _columnDateLabel(key),
      titles: titles,
      width: _readingWidth,
      dateHeaderHeight: _dateHeaderHeight,
      rowHeight: _rowHeight,
      showAddTitleRow: onAddTitle != null,
      valueForTitle: (title) => _recordValue(_recordAt(title.id, key), title),
      valueColorForTitle: (title) {
        final record = _recordAt(title.id, key);
        if (record == null) return AppColors.textSecondary;
        final value = isLabs
            ? (record as LabRecordModel).value
            : (record as VitalRecordModel).value;
        return _valueColor(value, title);
      },
      onEdit: () => onEditColumn(key),
    );
  }

  @override
  Widget build(BuildContext context) {
    final columnKeys = _sortedColumnKeys();

    return AdmissionDetailsSectionContainer(
      title: title,
      headerAction: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (addingColumn) ...[
                  if (saving)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else ...[
                    IconButton(
                      tooltip: 'Save column',
                      onPressed: onSaveColumn,
                      icon: const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 22,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cancel',
                      onPressed: onCancelAddColumn,
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.error,
                        size: 22,
                      ),
                    ),
                  ],
                ],
                if (!saving)
                  IconButton(
                    tooltip: addingColumn
                        ? 'Add new date column'
                        : 'Add readings column',
                    onPressed: onStartAddColumn,
                    icon: Icon(
                      addingColumn
                          ? Icons.add_circle_outline
                          : Icons.edit_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
              ],
            ),
      child: titles.isEmpty && onAddTitle == null
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No measurement titles configured.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      _TitleCell(
                        width: _titleWidth,
                        height: _headerHeight,
                        isHeader: true,
                        child: const Text('Title', style: _headerStyle),
                      ),
                      _TitleCell(
                        width: _titleWidth,
                        height: _dateHeaderHeight,
                        child: const SizedBox.shrink(),
                      ),
                      ...titles.map(
                        (t) => _TitleCell(
                          width: _titleWidth,
                          height: _rowHeight,
                          child: Text(
                            t.title.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      if (onAddTitle != null) _buildAddTitleRow(),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _ScrollCell(
                                width: _rangeWidth,
                                height: _headerHeight,
                                isHeader: true,
                                child: const Text('Range', style: _headerStyle),
                              ),
                              SizedBox(
                                width: _readingAreaWidth(columnKeys),
                                height: _headerHeight,
                                child: const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: Text(
                                      'Reading',
                                      style: _headerStyle,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _RangeColumn(
                                titles: titles,
                                width: _rangeWidth,
                                dateHeaderHeight: _dateHeaderHeight,
                                rowHeight: _rowHeight,
                                showAddTitleRow: onAddTitle != null,
                              ),
                              ...columnKeys.map(_buildReadingColumn),
                              if (addingColumn &&
                                  pendingColumn != null &&
                                  pendingColumn!.isNewColumn)
                                _EditingReadingColumn(
                                  pending: pendingColumn!,
                                  titles: titles,
                                  width: _readingWidth,
                                  dateHeaderHeight: _dateHeaderHeight,
                                  rowHeight: _rowHeight,
                                  saving: saving,
                                  onPickDate: onPickColumnDate,
                                  showAddTitleRow: onAddTitle != null,
                                  isLabs: isLabs,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),
    );
  }

  double _readingAreaWidth(List<String> columnKeys) {
    var width = 0.0;
    if (columnKeys.isNotEmpty) width += columnKeys.length * _readingWidth;
    if (addingColumn && pendingColumn?.isNewColumn == true) {
      width += _readingWidth;
    }
    return width > 0 ? width : _readingWidth;
  }

  Widget _buildAddTitleRow() {
    return _TitleCell(
      width: _titleWidth,
      height: _rowHeight,
      child: Center(
        child: addingTitle
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: isLabs ? 'Add lab' : 'Add vital',
                onPressed: onAddTitle,
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );
}

class _TitleCell extends StatelessWidget {
  const _TitleCell({
    required this.width,
    required this.height,
    required this.child,
    this.isHeader = false,
  });

  final double width;
  final double height;
  final Widget child;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isHeader ? AppColors.background : Colors.white,
          border: const Border(
            right: BorderSide(color: AppColors.border),
            bottom: BorderSide(color: AppColors.border),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ScrollCell extends StatelessWidget {
  const _ScrollCell({
    required this.width,
    required this.height,
    required this.child,
    this.isHeader = false,
  });

  final double width;
  final double height;
  final Widget child;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isHeader ? AppColors.background : Colors.white,
          border: const Border(
            right: BorderSide(color: AppColors.border),
            bottom: BorderSide(color: AppColors.border),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Align(
            alignment: isHeader ? Alignment.centerLeft : Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _RangeColumn extends StatelessWidget {
  const _RangeColumn({
    required this.titles,
    required this.width,
    required this.dateHeaderHeight,
    required this.rowHeight,
    this.showAddTitleRow = false,
  });

  final List<MeasurementTitleModel> titles;
  final double width;
  final double dateHeaderHeight;
  final double rowHeight;
  final bool showAddTitleRow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          _ScrollCell(
            width: width,
            height: dateHeaderHeight,
            child: const SizedBox.shrink(),
          ),
          ...titles.map(
            (t) => _ScrollCell(
              width: width,
              height: rowHeight,
              child: Text(
                _measurementRangeLabel(t),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (showAddTitleRow)
            _ScrollCell(
              width: width,
              height: rowHeight,
              child: const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

class _ReadingColumn extends StatelessWidget {
  const _ReadingColumn({
    required this.columnKey,
    required this.dateLabel,
    required this.titles,
    required this.width,
    required this.dateHeaderHeight,
    required this.rowHeight,
    required this.valueForTitle,
    required this.valueColorForTitle,
    required this.onEdit,
    this.showAddTitleRow = false,
  });

  final String columnKey;
  final String dateLabel;
  final List<MeasurementTitleModel> titles;
  final double width;
  final double dateHeaderHeight;
  final double rowHeight;
  final String Function(MeasurementTitleModel title) valueForTitle;
  final Color Function(MeasurementTitleModel title) valueColorForTitle;
  final VoidCallback onEdit;
  final bool showAddTitleRow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          _ScrollCell(
            width: width,
            height: dateHeaderHeight,
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(6),
              child: Center(
                child: Text(
                  dateLabel,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
          ...titles.map((t) {
            final value = valueForTitle(t);
            final color = value == '—'
                ? AppColors.textSecondary
                : valueColorForTitle(t);
            final hasValue = value != '—';

            return _ScrollCell(
              width: width,
              height: rowHeight,
              child: InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasValue
                        ? AppColors.background
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: hasValue
                        ? Border.all(color: AppColors.border)
                        : null,
                  ),
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ),
            );
          }),
          if (showAddTitleRow)
            _ScrollCell(
              width: width,
              height: rowHeight,
              child: const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

class _EditingReadingColumn extends StatelessWidget {
  const _EditingReadingColumn({
    required this.pending,
    required this.titles,
    required this.width,
    required this.dateHeaderHeight,
    required this.rowHeight,
    required this.saving,
    required this.onPickDate,
    this.showAddTitleRow = false,
    this.isLabs = false,
  });

  final PendingMeasurementColumnEntry pending;
  final List<MeasurementTitleModel> titles;
  final double width;
  final double dateHeaderHeight;
  final double rowHeight;
  final bool saving;
  final VoidCallback onPickDate;
  final bool showAddTitleRow;
  final bool isLabs;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          _ScrollCell(
            width: width,
            height: dateHeaderHeight,
            child: InkWell(
              onTap: saving ? null : onPickDate,
              borderRadius: BorderRadius.circular(6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Center(
                  child: Text(
                    admissionDetailsFormatDateTime(
                      pending.date.toIso8601String(),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
            ),
          ),
          ...titles.map((t) {
            final ctrl = pending.controllers[t.id]!;
            return _ScrollCell(
              width: width,
              height: rowHeight,
              child: TextField(
                controller: ctrl,
                enabled: !saving,
                keyboardType: (!isLabs && !t.isNumericValueType)
                    ? TextInputType.text
                    : const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: '—',
                  isDense: true,
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            );
          }),
          if (showAddTitleRow)
            _ScrollCell(
              width: width,
              height: rowHeight,
              child: const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}
