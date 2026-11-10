class VitalTitleRequest {
  const VitalTitleRequest({
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

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{'title': title, 'value_type': valueType};
    if (unit != null && unit!.isNotEmpty) body['unit'] = unit;
    if (normalRangeMin != null) body['normal_range_min'] = normalRangeMin;
    if (normalRangeMax != null) body['normal_range_max'] = normalRangeMax;
    return body;
  }
}
