import '../../admins/models/pagination_model.dart';
import 'vital_title_model.dart';

class VitalsTitlesPageResult {
  const VitalsTitlesPageResult({
    required this.items,
    required this.pagination,
  });

  final List<VitalTitleModel> items;
  final PaginationModel pagination;
}
