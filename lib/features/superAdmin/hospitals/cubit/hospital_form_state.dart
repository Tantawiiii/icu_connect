import 'package:equatable/equatable.dart';

abstract class HospitalFormState extends Equatable {
  const HospitalFormState();

  @override
  List<Object?> get props => [];
}

class HospitalFormInitial extends HospitalFormState {
  const HospitalFormInitial();
}

class HospitalFormLoading extends HospitalFormState {
  const HospitalFormLoading();
}

class HospitalFormSuccess extends HospitalFormState {
  const HospitalFormSuccess(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class HospitalFormFailure extends HospitalFormState {
  const HospitalFormFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
