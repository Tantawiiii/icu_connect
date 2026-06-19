class SwapBedSelection {
  const SwapBedSelection({
    required this.bedLabel,
    required this.admissionId,
    required this.patientName,
    required this.bedKey,
    this.groupId,
    this.groupName = '',
  });

  final String bedLabel;
  final int admissionId;
  final String patientName;
  final String bedKey;
  final int? groupId;
  final String groupName;
}
