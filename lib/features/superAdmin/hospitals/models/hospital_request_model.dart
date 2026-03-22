class HospitalRequest {
  final String name;
  final String location;
  final int totalBeds;
  final int availableBeds;

  const HospitalRequest({
    required this.name,
    required this.location,
    required this.totalBeds,
    required this.availableBeds,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'location': location,
        'total_beds': totalBeds,
        'available_beds': availableBeds,
      };
}
