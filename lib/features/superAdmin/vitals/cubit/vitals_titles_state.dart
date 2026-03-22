import 'package:equatable/equatable.dart';

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
  const VitalsTitlesLoaded(this.items);
  final List<VitalTitleModel> items;

  @override
  List<Object?> get props => [items];
}

class VitalsTitlesFailure extends VitalsTitlesState {
  const VitalsTitlesFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class VitalsTitlesActionLoading extends VitalsTitlesLoaded {
  const VitalsTitlesActionLoading(super.items);
}

class VitalsTitlesActionSuccess extends VitalsTitlesLoaded {
  const VitalsTitlesActionSuccess(super.items, this.message);
  final String message;

  @override
  List<Object?> get props => [items, message];
}

class VitalsTitlesActionFailure extends VitalsTitlesLoaded {
  const VitalsTitlesActionFailure(super.items, this.message);
  final String message;

  @override
  List<Object?> get props => [items, message];
}

