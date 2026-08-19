import 'package:equatable/equatable.dart';

class DrugActorRef extends Equatable {
  const DrugActorRef({this.id, this.name, this.email});

  final int? id;
  final String? name;
  final String? email;

  factory DrugActorRef.fromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) return const DrugActorRef();
    return DrugActorRef(
      id: (raw['id'] as num?)?.toInt(),
      name: raw['name']?.toString(),
      email: raw['email']?.toString(),
    );
  }

  String get displayName {
    final n = name?.trim() ?? '';
    if (n.isNotEmpty) return n;
    final e = email?.trim() ?? '';
    if (e.isNotEmpty) return e;
    if (id != null) return '#$id';
    return '';
  }

  @override
  List<Object?> get props => [id, name, email];
}

class DrugModel extends Equatable {
  const DrugModel({
    required this.id,
    required this.genericName,
    required this.tradeNames,
    required this.dosingGuidelines,
    required this.indications,
    required this.contraindications,
    required this.sideEffects,
    required this.pregnancy,
    required this.renalDoseAdjustment,
    required this.hepaticDoseAdjustment,
    required this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.createdBy,
    this.updatedBy,
  });

  final int id;
  final String genericName;
  final List<String> tradeNames;
  final List<String> dosingGuidelines;
  final List<String> indications;
  final List<String> contraindications;
  final List<String> sideEffects;
  final List<String> pregnancy;
  final String renalDoseAdjustment;
  final String hepaticDoseAdjustment;
  final String notes;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final DrugActorRef? createdBy;
  final DrugActorRef? updatedBy;

  bool get isArchived => deletedAt != null && deletedAt!.trim().isNotEmpty;

  factory DrugModel.fromJson(Map<String, dynamic> json) => DrugModel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    genericName: json['generic_name']?.toString() ?? '',
    tradeNames: _stringList(json['trade_names']),
    dosingGuidelines: _stringList(json['dosing_guidelines']),
    indications: _stringList(json['indications']),
    contraindications: _stringList(json['contraindications']),
    sideEffects: _stringList(json['side_effects']),
    pregnancy: _stringList(json['pregnancy']),
    renalDoseAdjustment: json['renal_dose_adjustment']?.toString() ?? '',
    hepaticDoseAdjustment: json['hepatic_dose_adjustment']?.toString() ?? '',
    notes: json['notes']?.toString() ?? '',
    isActive: json['is_active'] as bool? ?? true,
    createdAt: json['created_at']?.toString() ?? '',
    updatedAt: json['updated_at']?.toString() ?? '',
    deletedAt: json['deleted_at']?.toString(),
    createdBy: json['created_by'] == null
        ? null
        : DrugActorRef.fromJson(json['created_by']),
    updatedBy: json['updated_by'] == null
        ? null
        : DrugActorRef.fromJson(json['updated_by']),
  );

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  List<Object?> get props => [
    id,
    genericName,
    tradeNames,
    dosingGuidelines,
    indications,
    contraindications,
    sideEffects,
    pregnancy,
    renalDoseAdjustment,
    hepaticDoseAdjustment,
    notes,
    isActive,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
  ];
}
