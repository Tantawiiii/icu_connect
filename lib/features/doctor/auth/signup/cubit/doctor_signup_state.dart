import 'package:equatable/equatable.dart';

import '../models/doctor_signup_response.dart';
import '../models/signup_hospital_item.dart';

sealed class DoctorSignupState extends Equatable {
  const DoctorSignupState();

  @override
  List<Object?> get props => [];
}

final class DoctorSignupInitial extends DoctorSignupState {
  const DoctorSignupInitial();
}

final class DoctorSignupHospitalsLoading extends DoctorSignupState {
  const DoctorSignupHospitalsLoading();
}

final class DoctorSignupReady extends DoctorSignupState {
  const DoctorSignupReady({required this.hospitals, this.selectedHospitalId});

  final List<SignupHospitalItem> hospitals;
  final int? selectedHospitalId;

  @override
  List<Object?> get props => [hospitals, selectedHospitalId];
}

final class DoctorSignupHospitalsFailure extends DoctorSignupState {
  const DoctorSignupHospitalsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class DoctorSignupSubmitting extends DoctorSignupState {
  const DoctorSignupSubmitting({
    required this.hospitals,
    this.selectedHospitalId,
  });

  final List<SignupHospitalItem> hospitals;
  final int? selectedHospitalId;

  @override
  List<Object?> get props => [hospitals, selectedHospitalId];
}

final class DoctorSignupSuccess extends DoctorSignupState {
  const DoctorSignupSuccess(this.response);

  final DoctorSignupResponse response;

  @override
  List<Object?> get props => [response];
}

final class DoctorSignupSignupFailure extends DoctorSignupState {
  const DoctorSignupSignupFailure({
    required this.recover,
    required this.message,
  });

  final DoctorSignupReady recover;
  final String message;

  @override
  List<Object?> get props => [recover, message];
}
