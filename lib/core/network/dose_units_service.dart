import 'api_client.dart';
import 'api_constants.dart';
import 'services/base_api_service.dart';

/// A row from the shared dose-unit lookup table (`mg`, `g`, `mcg`, ...).
class DoseUnit {
  const DoseUnit({
    required this.id,
    required this.code,
    required this.label,
    required this.name,
    required this.sortOrder,
    required this.isActive,
  });

  final int id;
  final String code;
  final String label;
  final String name;
  final int sortOrder;
  final bool isActive;

  factory DoseUnit.fromJson(Map<String, dynamic> json) {
    final code = json['code']?.toString() ?? '';
    return DoseUnit(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: code,
      label: json['label']?.toString() ?? code,
      name: json['name']?.toString() ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

/// Fetches the shared dose-unit list — role-scoped since doctors/hospital
/// admins and super admins hit different endpoints for the same lookup data:
/// GET /hospital/dose-units vs GET /admin/dose-units.
class DoseUnitsService extends BaseApiService {
  const DoseUnitsService(super.role);

  Future<List<DoseUnit>> fetchAll() async {
    final data = await get<Map<String, dynamic>>(
      ApiConstants.doseUnits,
      cancelTag: 'dose_units_${role.name}',
    );
    final raw = data['data'];
    if (raw is! List) return const [];

    final units = raw
        .whereType<Map<String, dynamic>>()
        .map(DoseUnit.fromJson)
        .where((u) => u.isActive)
        .toList();
    units.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return units;
  }
}
