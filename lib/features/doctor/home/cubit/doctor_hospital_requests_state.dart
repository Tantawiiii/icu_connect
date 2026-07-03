import 'package:equatable/equatable.dart';

import '../../../superAdmin/hospitals/models/hospital_registration_request_model.dart';

abstract class DoctorHospitalRequestsState extends Equatable {
  const DoctorHospitalRequestsState();

  @override
  List<Object?> get props => [];
}

class DoctorHospitalRequestsInitial extends DoctorHospitalRequestsState {
  const DoctorHospitalRequestsInitial();
}

class DoctorHospitalRequestsLoading extends DoctorHospitalRequestsState {
  const DoctorHospitalRequestsLoading();
}

class DoctorHospitalRequestsLoaded extends DoctorHospitalRequestsState {
  const DoctorHospitalRequestsLoaded(this.requests);
  final List<HospitalRegistrationRequest> requests;

  @override
  List<Object?> get props => [requests];
}

class DoctorHospitalRequestsFailure extends DoctorHospitalRequestsState {
  const DoctorHospitalRequestsFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
