import 'package:equatable/equatable.dart';

import '../../admins/models/pagination_model.dart';
import '../models/hospital_model.dart';

abstract class HospitalsState extends Equatable {
  const HospitalsState();

  @override
  List<Object?> get props => [];
}

class HospitalsInitial extends HospitalsState {
  const HospitalsInitial();
}

class HospitalsLoading extends HospitalsState {
  const HospitalsLoading();
}

class HospitalsLoaded extends HospitalsState {
  const HospitalsLoaded(this.hospitals, this.pagination);
  final List<HospitalModel> hospitals;
  final PaginationModel pagination;

  @override
  List<Object?> get props => [hospitals, pagination];
}

class HospitalsFailure extends HospitalsState {
  const HospitalsFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Emitted while a delete/restore action is in progress.
class HospitalsActionLoading extends HospitalsLoaded {
  const HospitalsActionLoading(super.hospitals, super.pagination);
}

/// Emitted after a successful delete/restore; includes a feedback message.
class HospitalsActionSuccess extends HospitalsLoaded {
  const HospitalsActionSuccess(super.hospitals, super.pagination, this.message);
  final String message;

  @override
  List<Object?> get props => [hospitals, pagination, message];
}

/// Emitted when a delete/restore action fails.
class HospitalsActionFailure extends HospitalsLoaded {
  const HospitalsActionFailure(super.hospitals, super.pagination, this.message);
  final String message;

  @override
  List<Object?> get props => [hospitals, pagination, message];
}
