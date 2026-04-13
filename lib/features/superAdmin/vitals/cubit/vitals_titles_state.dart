import 'package:equatable/equatable.dart';

import '../../admins/models/pagination_model.dart';
import '../models/vital_title_model.dart';

abstract class VitalsTitlesState extends Equatable {
  const VitalsTitlesState();

  @override
  List<Object?> get props => [];
}

class VitalsTitlesInitial extends VitalsTitlesState {
  const VitalsTitlesInitial();
}

class VitalsTitlesLoading extends VitalsTitlesState {
  const VitalsTitlesLoading();
}

class VitalsTitlesLoaded extends VitalsTitlesState {
  const VitalsTitlesLoaded(this.items, this.pagination);
  final List<VitalTitleModel> items;
  final PaginationModel pagination;

  @override
  List<Object?> get props => [items, pagination];
}

class VitalsTitlesFailure extends VitalsTitlesState {
  const VitalsTitlesFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class VitalsTitlesActionLoading extends VitalsTitlesLoaded {
  const VitalsTitlesActionLoading(super.items, super.pagination);
}

class VitalsTitlesActionSuccess extends VitalsTitlesLoaded {
  const VitalsTitlesActionSuccess(super.items, super.pagination, this.message);
  final String message;

  @override
  List<Object?> get props => [items, pagination, message];
}

class VitalsTitlesActionFailure extends VitalsTitlesLoaded {
  const VitalsTitlesActionFailure(super.items, super.pagination, this.message);
  final String message;

  @override
  List<Object?> get props => [items, pagination, message];
}

