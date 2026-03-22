import 'package:equatable/equatable.dart';

abstract class PatientFormState extends Equatable {
  const PatientFormState();

  @override
  List<Object?> get props => [];
}

class PatientFormInitial extends PatientFormState {
  const PatientFormInitial();
}

class PatientFormLoading extends PatientFormState {
  const PatientFormLoading();
}

class PatientFormSuccess extends PatientFormState {
  const PatientFormSuccess(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class PatientFormFailure extends PatientFormState {
  const PatientFormFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

