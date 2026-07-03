import '../constants/app_texts.dart';

class MeasurementTitleFormValues {
  const MeasurementTitleFormValues({
    required this.title,
    this.unit,
    this.valueType = 'numeric',
    this.normalRangeMin,
    this.normalRangeMax,
  });

  final String title;
  final String? unit;
  final String valueType;
  final double? normalRangeMin;
  final double? normalRangeMax;

  static const maxTitleLength = 255;

  static String? validateTitle(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return 'Title is required';
    if (value.length > maxTitleLength) {
      return 'Title must be at most $maxTitleLength characters';
    }
    return null;
  }

  static String? validateRangeMin(String? raw, {String? maxRaw}) {
    final minText = raw?.trim() ?? '';
    final maxText = maxRaw?.trim() ?? '';
    if (minText.isEmpty && maxText.isEmpty) return null;
    if (minText.isEmpty) {
      return 'Min range is required when max is set';
    }
    if (double.tryParse(minText) == null) return 'Invalid number';
    return null;
  }

  static String? validateRangeMax(String? raw, {String? minRaw}) {
    final maxText = raw?.trim() ?? '';
    final minText = minRaw?.trim() ?? '';
    if (minText.isEmpty && maxText.isEmpty) return null;
    if (maxText.isEmpty) {
      return 'Max range is required when min is set';
    }
    final maxVal = double.tryParse(maxText);
    if (maxVal == null) return 'Invalid number';
    final minVal = double.tryParse(minText);
    if (minVal != null && maxVal <= minVal) {
      return AppTexts.normalRangeMaxMustExceedMin;
    }
    return null;
  }

  static MeasurementTitleFormValues? fromFields({
    required String title,
    required String unit,
    required String min,
    required String max,
    String valueType = 'numeric',
  }) {
    final titleError = validateTitle(title);
    final minError = validateRangeMin(min, maxRaw: max);
    final maxError = validateRangeMax(max, minRaw: min);
    if (titleError != null || minError != null || maxError != null) {
      return null;
    }

    final unitText = unit.trim();
    final minText = min.trim();
    final maxText = max.trim();

    return MeasurementTitleFormValues(
      title: title.trim(),
      unit: unitText.isEmpty ? null : unitText,
      valueType: valueType,
      normalRangeMin: minText.isEmpty ? null : double.parse(minText),
      normalRangeMax: maxText.isEmpty ? null : double.parse(maxText),
    );
  }

  Map<String, dynamic> toVitalJson() {
    final body = <String, dynamic>{
      'title': title,
      'value_type': valueType,
    };
    if (unit != null && unit!.isNotEmpty) body['unit'] = unit;
    if (normalRangeMin != null) body['normal_range_min'] = normalRangeMin;
    if (normalRangeMax != null) body['normal_range_max'] = normalRangeMax;
    return body;
  }

  Map<String, dynamic> toLabJson() {
    final body = <String, dynamic>{'title': title};
    if (unit != null && unit!.isNotEmpty) body['unit'] = unit;
    if (normalRangeMin != null) body['normal_range_min'] = normalRangeMin;
    if (normalRangeMax != null) body['normal_range_max'] = normalRangeMax;
    return body;
  }
}
