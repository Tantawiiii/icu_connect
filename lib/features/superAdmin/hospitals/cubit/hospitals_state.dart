import 'package:equatable/equatable.dart';

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
  const HospitalsLoaded(this.hospitals);
  final List<HospitalModel> hospitals;

  @override
  List<Object?> get props => [hospitals];
}

class HospitalsFailure extends HospitalsState {
  const HospitalsFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Emitted while a delete/restore action is in progress.
class HospitalsActionLoading extends HospitalsLoaded {
  const HospitalsActionLoading(super.hospitals);
}

/// Emitted after a successful delete/restore; includes a feedback message.
class HospitalsActionSuccess extends HospitalsLoaded {
  const HospitalsActionSuccess(super.hospitals, this.message);
  final String message;

  @override
  List<Object?> get props => [hospitals, message];
}

/// Emitted when a delete/restore action fails.
class HospitalsActionFailure extends HospitalsLoaded {
  const HospitalsActionFailure(super.hospitals, this.message);
  final String message;

  @override
  List<Object?> get props => [hospitals, message];
}
