class HospitalEntry {
  HospitalEntry({
    required this.hospitalId,
    required this.hospitalName,
    required this.role,
    this.status,
  });

  int hospitalId;
  String hospitalName;
  String role;
  String? status;
}

