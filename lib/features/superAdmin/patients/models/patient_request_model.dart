class PatientRequest {
  const PatientRequest({
    this.name,
    this.nationalId,
    this.age,
    this.gender,
    this.phone,
    this.bloodGroup,
    this.notes,
  });

  final String? name;
  final String? nationalId;
  final int? age;
  final String? gender;
  final String? phone;
  final String? bloodGroup;
  final String? notes;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (nationalId != null) map['national_id'] = nationalId;
    if (age != null) map['age'] = age;
    if (gender != null) map['gender'] = gender;
    if (phone != null) map['phone'] = phone;
    if (bloodGroup != null) map['blood_group'] = bloodGroup;
    if (notes != null) map['notes'] = notes;
    return map;
  }
}

