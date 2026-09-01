import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/services/base_api_service.dart';
import '../../../superAdmin/drugs/models/drug_model.dart';
import '../../../superAdmin/drugs/models/drug_request.dart';

/// Hospital-scoped drug list for medical forms (search / dropdowns).
class HospitalDrugsRepository extends BaseApiService {
  const HospitalDrugsRepository() : super(UserRole.hospital);

  /// GET /drugs/formulary — flat active list for medical forms (optional search).
  Future<List<DrugModel>> fetchDrugs({String? search}) async {
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
  }

  /// POST /drugs — add a new drug to the shared formulary from the app.
  Future<DrugModel> createDrug(DrugRequest request) async {
    final data = await post<Map<String, dynamic>>(
      ApiConstants.drugs,
      data: request.toJson(),
      cancelTag: 'hospital_drugs_create',
    );
    return DrugModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// POST /ai/drugs/lookup — AI-assisted prefill for the add-drug form.
  /// At least one of [genericName] / [tradeNames] must be provided.
  ///
  /// Response shape: `{ data: { drug: {...fields, found, confidence,
  /// missing_fields}, raw: {...model usage metadata, ignored} } }`.
  Future<AiDrugLookupResult> lookupDrugWithAi({
    String? genericName,
    List<String> tradeNames = const [],
    String language = 'en',
    bool refresh = false,
  }) async {
    final body = <String, dynamic>{'language': language, 'refresh': refresh};
    final name = genericName?.trim() ?? '';
    if (name.isNotEmpty) body['generic_name'] = name;
    if (tradeNames.isNotEmpty) body['trade_names'] = tradeNames;

    final data = await post<Map<String, dynamic>>(
      ApiConstants.aiDrugsLookup,
      data: body,
      cancelTag: 'hospital_drugs_ai_lookup',
    );
    final payload = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;
    final drugJson = payload['drug'] is Map<String, dynamic>
        ? payload['drug'] as Map<String, dynamic>
        : payload;
    return AiDrugLookupResult.fromJson(drugJson);
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
