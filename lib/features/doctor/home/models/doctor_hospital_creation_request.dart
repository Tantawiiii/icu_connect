class DoctorHospitalCreationRequest {
  final String name;
  final String location;
  final List<DoctorHospitalRequestGroup> groups;

  const DoctorHospitalCreationRequest({
    required this.name,
    required this.location,
    required this.groups,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'location': location,
        'groups': groups.map((g) => g.toJson()).toList(),
      };
}

class DoctorHospitalRequestGroup {
  final String name;
  final int totalBeds;

  const DoctorHospitalRequestGroup({
    required this.name,
    required this.totalBeds,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'total_beds': totalBeds,
        'available_beds': totalBeds,
      };
}
