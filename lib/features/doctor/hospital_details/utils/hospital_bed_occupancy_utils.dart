import '../../../superAdmin/patients/models/patient_admission_models.dart';
import '../enums/admission_status.dart';
import '../widgets/hospital_group_bed_card.dart';

bool admissionOccupiesBed(PatientAdmissionModel admission) {
  if (!AdmissionStatus.fromApiValue(admission.status).occupiesBed) {
    return false;
  }
  final leave = admission.dateLeave;
  if (leave != null && leave.trim().isNotEmpty) return false;
  return normalizeBedNumber(admission.bedNumber).isNotEmpty;
}

List<PatientAdmissionModel> filterAdmissionsBySearch(
  List<PatientAdmissionModel> admissions,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return admissions;

  return admissions.where((admission) {
    if (normalizeBedNumber(admission.bedNumber).contains(q)) return true;
    if (admission.bedNumber.toLowerCase().contains(q)) return true;
    final name = admission.patient?.name.toLowerCase() ?? '';
    return name.contains(q);
  }).toList();
}

BedOccupancyData buildBedOccupancyForGroup(
  List<PatientAdmissionModel> admissions,
  int? groupId,
) {
  final occupied = <String>{};
  final admissionIds = <String, int>{};
  final patientNames = <String, String>{};

  for (final admission in admissions) {
    if (!admissionOccupiesBed(admission)) continue;
    if (groupId != null && admission.hospitalGroupId != groupId) continue;

    final bed = normalizeBedNumber(admission.bedNumber);
    if (bed.isEmpty) continue;

    occupied.add(bed);
    final key = bedOccupancyLookupKey(groupId, bed);
    admissionIds[key] = admission.id;

    final name = admission.patient?.name.trim();
    if (name != null && name.isNotEmpty) {
      patientNames[key] = name;
    }
  }

  return BedOccupancyData(
    occupiedBedLabels: occupied,
    admissionIdByBedKey: admissionIds,
    patientNameByBedKey: patientNames,
  );
}

int countOccupiedBeds(List<PatientAdmissionModel> admissions) {
  var count = 0;
  for (final admission in admissions) {
    if (!admissionOccupiesBed(admission)) continue;
    if (normalizeBedNumber(admission.bedNumber).isEmpty) continue;
    count++;
  }
  return count;
}

Map<int, int> occupiedCountByGroupId(List<PatientAdmissionModel> admissions) {
  final counts = <int, int>{};
  for (final admission in admissions) {
    if (!admissionOccupiesBed(admission)) continue;
    if (normalizeBedNumber(admission.bedNumber).isEmpty) continue;
    final gid = admission.hospitalGroupId;
    if (gid == null) continue;
    counts[gid] = (counts[gid] ?? 0) + 1;
  }
  return counts;
}
