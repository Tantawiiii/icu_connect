import 'package:equatable/equatable.dart';

import '../models/doctor_hospital.dart';

sealed class DoctorHospitalsState extends Equatable {
  const DoctorHospitalsState();

  @override
  List<Object?> get props => [];
}

class DoctorHospitalsInitial extends DoctorHospitalsState {
  const DoctorHospitalsInitial();
}

class DoctorHospitalsLoading extends DoctorHospitalsState {
  const DoctorHospitalsLoading();
}

class DoctorHospitalsLoaded extends DoctorHospitalsState {
  const DoctorHospitalsLoaded(this.hospitals);

  final List<DoctorHospital> hospitals;

  @override
  List<Object?> get props => [hospitals];
}

class DoctorHospitalsFailure extends DoctorHospitalsState {
  const DoctorHospitalsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
