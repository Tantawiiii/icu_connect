import 'package:equatable/equatable.dart';

class SignupHospitalItem extends Equatable {
  const SignupHospitalItem({
    required this.id,
    required this.name,
    this.location,
  });

  final int id;
  final String name;
  final String? location;

  factory SignupHospitalItem.fromJson(Map<String, dynamic> json) {
    return SignupHospitalItem(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      location: json['location'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, location];
}
