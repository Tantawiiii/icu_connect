import 'package:equatable/equatable.dart';

class DashboardOverview extends Equatable {
  const DashboardOverview({
    required this.totalHospitals,
    required this.totalPatients,
    required this.totalDoctors,
    required this.totalAdmissions,
    required this.activeAdmissions,
    required this.totalBeds,
    required this.availableBeds,
  });

  final int totalHospitals;
  final int totalPatients;
  final int totalDoctors;
  final int totalAdmissions;
  final int activeAdmissions;
  final String totalBeds;
  final String availableBeds;

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      totalHospitals: _toInt(json['total_hospitals']),
      totalPatients: _toInt(json['total_patients']),
      totalDoctors: _toInt(json['total_doctors']),
      totalAdmissions: _toInt(json['total_admissions']),
      activeAdmissions: _toInt(json['active_admissions']),
      totalBeds: json['total_beds']?.toString() ?? '0',
      availableBeds: json['available_beds']?.toString() ?? '0',
    );
  }

  static int _toInt(dynamic v) => (v as num?)?.toInt() ?? 0;

  @override
  List<Object?> get props => [
        totalHospitals,
        totalPatients,
        totalDoctors,
        totalAdmissions,
        activeAdmissions,
        totalBeds,
        availableBeds,
      ];
}

class DashboardRecentAdmission extends Equatable {
  const DashboardRecentAdmission({
    required this.id,
    this.patientId,
    this.patientName,
    this.hospitalName,
    this.bedNumber,
    this.status,
    this.dateComes,
  });

  final int id;
  final int? patientId;
  final String? patientName;
  final String? hospitalName;
  final String? bedNumber;
  final String? status;
  final String? dateComes;

  factory DashboardRecentAdmission.fromJson(Map<String, dynamic> json) {
    final patient = json['patient'] as Map<String, dynamic>?;
    final hospital = json['hospital'] as Map<String, dynamic>?;
    final idVal = json['id'];
    return DashboardRecentAdmission(
      id: idVal is int ? idVal : (idVal as num?)?.toInt() ?? 0,
      patientId: (json['patient_id'] as num?)?.toInt(),
      patientName: patient?['name'] as String?,
      hospitalName: hospital?['name'] as String?,
      bedNumber: json['bed_number'] as String?,
      status: json['status'] as String?,
      dateComes: json['date_comes'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        patientId,
        patientName,
        hospitalName,
        bedNumber,
        status,
        dateComes,
      ];
}

class AdminDashboardData extends Equatable {
  const AdminDashboardData({
    required this.overview,
    required this.recentAdmissions,
  });

  final DashboardOverview overview;
  final List<DashboardRecentAdmission> recentAdmissions;

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    return AdminDashboardData(
      overview: DashboardOverview.fromJson(
        json['overview'] as Map<String, dynamic>,
      ),
      recentAdmissions: (json['recent_admissions'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DashboardRecentAdmission.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [overview, recentAdmissions];
}
