import 'package:equatable/equatable.dart';

import '../models/lab_title_model.dart';

abstract class LabsTitlesState extends Equatable {
  const LabsTitlesState();

  @override
  List<Object?> get props => [];
}

class LabsTitlesInitial extends LabsTitlesState {
  const LabsTitlesInitial();
}

class LabsTitlesLoading extends LabsTitlesState {
  const LabsTitlesLoading();
}

class LabsTitlesLoaded extends LabsTitlesState {
  const LabsTitlesLoaded(this.items);
  final List<LabTitleModel> items;

  @override
  List<Object?> get props => [items];
}

class LabsTitlesFailure extends LabsTitlesState {
  const LabsTitlesFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class LabsTitlesActionLoading extends LabsTitlesLoaded {
  const LabsTitlesActionLoading(super.items);
}

class LabsTitlesActionSuccess extends LabsTitlesLoaded {
  const LabsTitlesActionSuccess(super.items, this.message);
  final String message;

  @override
  List<Object?> get props => [items, message];
}

class LabsTitlesActionFailure extends LabsTitlesLoaded {
  const LabsTitlesActionFailure(super.items, this.message);
  final String message;

  @override
  List<Object?> get props => [items, message];
}

