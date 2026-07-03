class LabTitleRequest {
  const LabTitleRequest({
    required this.title,
    this.unit,
    this.normalRangeMin,
    this.normalRangeMax,
  });

  final String title;
  final String? unit;
  final double? normalRangeMin;
  final double? normalRangeMax;

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{'title': title};
    if (unit != null && unit!.isNotEmpty) body['unit'] = unit;
    if (normalRangeMin != null) body['normal_range_min'] = normalRangeMin;
    if (normalRangeMax != null) body['normal_range_max'] = normalRangeMax;
    return body;
  }
}
