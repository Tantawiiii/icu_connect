import 'package:equatable/equatable.dart';

import '../models/hospital_doctor.dart';

sealed class HospitalDoctorsState extends Equatable {
  const HospitalDoctorsState();

  @override
  List<Object?> get props => [];
}

class HospitalDoctorsInitial extends HospitalDoctorsState {
  const HospitalDoctorsInitial();
}

class HospitalDoctorsLoading extends HospitalDoctorsState {
  const HospitalDoctorsLoading();
}

class HospitalDoctorsLoaded extends HospitalDoctorsState {
  const HospitalDoctorsLoaded({
    required this.doctors,
    this.acceptingIds = const <int>{},
    this.activatingIds = const <int>{},
    this.creating = false,
  });

  final List<HospitalDoctor> doctors;
  final Set<int> acceptingIds;
  final Set<int> activatingIds;
  final bool creating;

  HospitalDoctorsLoaded copyWith({
    List<HospitalDoctor>? doctors,
    Set<int>? acceptingIds,
    Set<int>? activatingIds,
    bool? creating,
  }) {
    return HospitalDoctorsLoaded(
      doctors: doctors ?? this.doctors,
      acceptingIds: acceptingIds ?? this.acceptingIds,
      activatingIds: activatingIds ?? this.activatingIds,
      creating: creating ?? this.creating,
    );
  }

  @override
  List<Object?> get props => [
    doctors,
    acceptingIds.toList()..sort(),
    activatingIds.toList()..sort(),
    creating,
  ];
}

class HospitalDoctorsFailure extends HospitalDoctorsState {
  const HospitalDoctorsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

