import 'package:equatable/equatable.dart';

import '../../admins/models/pagination_model.dart';
import '../models/hospital_registration_request_model.dart';

abstract class HospitalRequestsState extends Equatable {
  const HospitalRequestsState();

  @override
  List<Object?> get props => [];
}

class HospitalRequestsInitial extends HospitalRequestsState {
  const HospitalRequestsInitial();
}

class HospitalRequestsLoading extends HospitalRequestsState {
  const HospitalRequestsLoading();
}

class HospitalRequestsLoaded extends HospitalRequestsState {
  const HospitalRequestsLoaded(
    this.requests,
    this.pagination,
    this.approvalStatusFilter,
  );

  final List<HospitalRegistrationRequest> requests;
  final PaginationModel pagination;
  final String? approvalStatusFilter;

  @override
  List<Object?> get props => [requests, pagination, approvalStatusFilter];
}

class HospitalRequestsFailure extends HospitalRequestsState {
  const HospitalRequestsFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class HospitalRequestsActionLoading extends HospitalRequestsLoaded {
  const HospitalRequestsActionLoading(
    super.requests,
    super.pagination,
    super.approvalStatusFilter,
  );
}

class HospitalRequestsActionSuccess extends HospitalRequestsLoaded {
  const HospitalRequestsActionSuccess(
    super.requests,
    super.pagination,
    super.approvalStatusFilter,
    this.message,
  );

  final String message;

  @override
  List<Object?> get props => [requests, pagination, approvalStatusFilter, message];
}

class HospitalRequestsActionFailure extends HospitalRequestsLoaded {
  const HospitalRequestsActionFailure(
    super.requests,
    super.pagination,
    super.approvalStatusFilter,
    this.message,
  );

  final String message;

  @override
  List<Object?> get props => [requests, pagination, approvalStatusFilter, message];
}
