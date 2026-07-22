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
