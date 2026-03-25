import 'package:equatable/equatable.dart';

import '../../auth/signup/models/signup_hospital_item.dart';
import '../models/doctor_profile.dart';

sealed class DoctorProfileState extends Equatable {
  const DoctorProfileState();

  @override
  List<Object?> get props => [];
}

final class DoctorProfileInitial extends DoctorProfileState {
  const DoctorProfileInitial();
}

final class DoctorProfileLoading extends DoctorProfileState {
  const DoctorProfileLoading();
}

final class DoctorProfileLoadFailure extends DoctorProfileState {
  const DoctorProfileLoadFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class DoctorProfileReady extends DoctorProfileState {
  const DoctorProfileReady({
    required this.profile,
    required this.catalogHospitals,
    required this.hospitalIds,
    this.isSaving = false,
  });

  final DoctorProfile profile;
  final List<SignupHospitalItem> catalogHospitals;
  /// Hospital IDs sent on save (profile links + new join requests).
  final List<int> hospitalIds;
  final bool isSaving;

  DoctorProfileReady copyWith({
    DoctorProfile? profile,
    List<SignupHospitalItem>? catalogHospitals,
    List<int>? hospitalIds,
    bool? isSaving,
  }) {
    return DoctorProfileReady(
      profile: profile ?? this.profile,
      catalogHospitals: catalogHospitals ?? this.catalogHospitals,
      hospitalIds: hospitalIds ?? this.hospitalIds,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props =>
      [profile, catalogHospitals, hospitalIds, isSaving];
}

final class DoctorProfileSaveFailure extends DoctorProfileState {
  const DoctorProfileSaveFailure({
    required this.recover,
    required this.message,
  });

  final DoctorProfileReady recover;
  final String message;

  @override
  List<Object?> get props => [recover, message];
}
