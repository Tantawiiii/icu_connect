class LabTitleRequest {
  const LabTitleRequest({
    required this.title,
    required this.unit,
    required this.normalRangeMin,
    required this.normalRangeMax,
  });

  final String title;
  final String unit;
  final double normalRangeMin;
  final double normalRangeMax;

  Map<String, dynamic> toJson() => {
        'title': title,
        'unit': unit,
        'normal_range_min': normalRangeMin,
        'normal_range_max': normalRangeMax,
      };
}

