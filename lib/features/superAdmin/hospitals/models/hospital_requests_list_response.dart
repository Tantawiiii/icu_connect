import 'package:equatable/equatable.dart';

import '../../admins/models/pagination_model.dart';
import 'hospital_registration_request_model.dart';

class HospitalRequestsListResponse extends Equatable {
  const HospitalRequestsListResponse({
    required this.data,
    required this.pagination,
  });

  final List<HospitalRegistrationRequest> data;
  final PaginationModel pagination;

  factory HospitalRequestsListResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final list = raw is List<dynamic>
        ? raw
              .whereType<Map<String, dynamic>>()
              .map(HospitalRegistrationRequest.fromJson)
              .toList()
        : <HospitalRegistrationRequest>[];

    final paginationJson = json['pagination'] as Map<String, dynamic>?;
    final pagination = paginationJson != null
        ? PaginationModel.fromJson(paginationJson)
        : PaginationModel(
            currentPage: 1,
            from: list.isEmpty ? 0 : 1,
            to: list.length,
            total: list.length,
            perPage: list.length,
            lastPage: 1,
          );

    return HospitalRequestsListResponse(data: list, pagination: pagination);
  }

  @override
  List<Object?> get props => [data, pagination];
}
