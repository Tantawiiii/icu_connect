import 'package:equatable/equatable.dart';

import '../models/patient_model.dart';

abstract class PatientDetailsState extends Equatable {
  const PatientDetailsState();

  @override
  List<Object?> get props => [];
}

class PatientDetailsInitial extends PatientDetailsState {
  const PatientDetailsInitial();
}

class PatientDetailsLoading extends PatientDetailsState {
  const PatientDetailsLoading();
}

class PatientDetailsLoaded extends PatientDetailsState {
  const PatientDetailsLoaded(this.patient);
  final PatientModel patient;

  @override
  List<Object?> get props => [patient];
}

class PatientDetailsFailure extends PatientDetailsState {
  const PatientDetailsFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

