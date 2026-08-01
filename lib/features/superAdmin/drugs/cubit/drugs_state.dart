import 'package:equatable/equatable.dart';

import '../../admins/models/pagination_model.dart';
import '../models/drug_model.dart';

enum DrugsListFilter { all, active, inactive, archived }

abstract class DrugsState extends Equatable {
  const DrugsState();

  @override
  List<Object?> get props => [];
}

class DrugsInitial extends DrugsState {
  const DrugsInitial();
}

class DrugsLoading extends DrugsState {
  const DrugsLoading();
}

class DrugsLoaded extends DrugsState {
  const DrugsLoaded(
    this.items,
    this.pagination, {
    this.filter = DrugsListFilter.all,
    this.search = '',
  });

  final List<DrugModel> items;
  final PaginationModel pagination;
  final DrugsListFilter filter;
  final String search;

  @override
  List<Object?> get props => [items, pagination, filter, search];
}

class DrugsFailure extends DrugsState {
  const DrugsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class DrugsActionLoading extends DrugsLoaded {
  const DrugsActionLoading(
    super.items,
    super.pagination, {
    super.filter,
    super.search,
  });
}

class DrugsActionSuccess extends DrugsLoaded {
  const DrugsActionSuccess(
    super.items,
    super.pagination,
    this.message, {
    super.filter,
    super.search,
  });

  final String message;

  @override
  List<Object?> get props => [items, pagination, filter, search, message];
}

class DrugsActionFailure extends DrugsLoaded {
  const DrugsActionFailure(
    super.items,
    super.pagination,
    this.message, {
    super.filter,
    super.search,
  });

  final String message;

  @override
  List<Object?> get props => [items, pagination, filter, search, message];
}
