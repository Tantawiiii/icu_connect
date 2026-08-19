class DrugRequest {
  const DrugRequest({
    required this.genericName,
    this.tradeNames = const [],
    this.dosingGuidelines = const [],
    this.indications = const [],
    this.contraindications = const [],
    this.sideEffects = const [],
    this.pregnancy = const [],
    this.renalDoseAdjustment,
    this.hepaticDoseAdjustment,
    this.notes,
    this.isActive = true,
  });

  final String genericName;
  final List<String> tradeNames;
  final List<String> dosingGuidelines;
  final List<String> indications;
  final List<String> contraindications;
  final List<String> sideEffects;
  final List<String> pregnancy;
  final String? renalDoseAdjustment;
  final String? hepaticDoseAdjustment;
  final String? notes;
  final bool isActive;

  /// Parses a drug JSON payload (drug record or AI lookup result — same
  /// shape minus server-only fields) into editable form values.
  factory DrugRequest.fromJson(Map<String, dynamic> json) {
    return DrugRequest(
      genericName: json['generic_name']?.toString() ?? '',
      tradeNames: _stringList(json['trade_names']),
      dosingGuidelines: _stringList(json['dosing_guidelines']),
      indications: _stringList(json['indications']),
      contraindications: _stringList(json['contraindications']),
      sideEffects: _stringList(json['side_effects']),
      pregnancy: _stringList(json['pregnancy']),
      renalDoseAdjustment: json['renal_dose_adjustment']?.toString(),
      hepaticDoseAdjustment: json['hepatic_dose_adjustment']?.toString(),
      notes: json['notes']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{
      'generic_name': genericName.trim(),
      'is_active': isActive,
      'trade_names': tradeNames,
      'dosing_guidelines': dosingGuidelines,
      'indications': indications,
      'contraindications': contraindications,
      'side_effects': sideEffects,
      'pregnancy': pregnancy,
    };

    final renal = renalDoseAdjustment?.trim() ?? '';
    final hepatic = hepaticDoseAdjustment?.trim() ?? '';
    final noteText = notes?.trim() ?? '';
    if (renal.isNotEmpty) body['renal_dose_adjustment'] = renal;
    if (hepatic.isNotEmpty) body['hepatic_dose_adjustment'] = hepatic;
    if (noteText.isNotEmpty) body['notes'] = noteText;
    return body;
  }
}
