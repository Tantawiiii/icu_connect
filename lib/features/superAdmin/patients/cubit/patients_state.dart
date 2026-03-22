import 'package:equatable/equatable.dart';

import '../models/patient_model.dart';

abstract class PatientsState extends Equatable {
  const PatientsState();

  @override
  List<Object?> get props => [];
}

class PatientsInitial extends PatientsState {
  const PatientsInitial();
}

class PatientsLoading extends PatientsState {
  const PatientsLoading();
}

class PatientsLoaded extends PatientsState {
  const PatientsLoaded(this.patients);
  final List<PatientModel> patients;

  @override
  List<Object?> get props => [patients];
}

class PatientsFailure extends PatientsState {
  const PatientsFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class PatientsActionLoading extends PatientsLoaded {
  const PatientsActionLoading(super.patients);
}

class PatientsActionSuccess extends PatientsLoaded {
  const PatientsActionSuccess(super.patients, this.message);
  final String message;

  @override
  List<Object?> get props => [patients, message];
}

class PatientsActionFailure extends PatientsLoaded {
  const PatientsActionFailure(super.patients, this.message);
  final String message;

  @override
  List<Object?> get props => [patients, message];
}

