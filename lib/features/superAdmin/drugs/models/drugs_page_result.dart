import '../../admins/models/pagination_model.dart';
import 'drug_model.dart';

class DrugsPageResult {
  const DrugsPageResult({
    required this.items,
    required this.pagination,
  });

  final List<DrugModel> items;
  final PaginationModel pagination;
}
