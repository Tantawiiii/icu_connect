import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/services/base_api_service.dart';
import '../../../superAdmin/drugs/models/drug_model.dart';

/// Hospital-scoped drug list for medical forms (search / dropdowns).
class HospitalDrugsRepository extends BaseApiService {
  const HospitalDrugsRepository() : super(UserRole.hospital);

  /// GET /drugs/formulary — flat active list for medical forms (optional search).
  Future<List<DrugModel>> fetchDrugs({String? search}) async {
    try {
      final query = <String, dynamic>{};
      final q = search?.trim() ?? '';
      if (q.isNotEmpty) query['search'] = q;

      final data = await get<Map<String, dynamic>>(
        ApiConstants.drugsFormulary,
        queryParameters: query.isEmpty ? null : query,
        cancelTag: 'hospital_drugs_${q.isEmpty ? 'all' : q}',
      );

      final raw = data['data'];
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(DrugModel.fromJson)
            .toList();
      }
      return const [];
    } on NetworkException {
      rethrow;
    }
  }
}

String hospitalDrugDisplayName(DrugModel drug) {
  final generic = drug.genericName.trim();
  if (drug.tradeNames.isNotEmpty) {
    final trade = drug.tradeNames.first.trim();
    if (trade.isNotEmpty && generic.isNotEmpty) {
      return '$trade ($generic)';
    }
    if (trade.isNotEmpty) return trade;
  }
  return generic.isEmpty ? 'Drug #${drug.id}' : generic;
}
