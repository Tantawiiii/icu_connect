class HospitalRequest {
  final String name;
  final String? location;
  final List<HospitalGroupRequest> groups;

  const HospitalRequest({
    required this.name,
    this.location,
    required this.groups,
  });

  Map<String, dynamic> toCreateJson() => {
        'name': name,
        'location': location ?? '',
        'groups': groups.map((g) => g.toJson()).toList(),
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        if (location != null) 'location': location,
        'groups': groups.map((g) => g.toJson()).toList(),
      };
}

class HospitalGroupRequest {
  final int? id;
  final String? name;
  final int? totalBeds;
  final int? availableBeds;
  final bool delete;

  const HospitalGroupRequest({
    this.id,
    this.name,
    this.totalBeds,
    this.availableBeds,
    this.delete = false,
  });

  Map<String, dynamic> toJson() {
    if (delete) {
      return {
        if (id != null) 'id': id,
        '_delete': true,
      };
    }
    return {
      if (id != null) 'id': id,
      'name': name ?? '',
      'total_beds': totalBeds ?? 0,
      'available_beds': availableBeds ?? 0,
    };
  }
}
