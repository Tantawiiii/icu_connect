enum AdmissionStatus {
  admitted('admitted'),
  active('active'),
  inactive('inactive'),
  discharged('discharged'),
  leavesAma('leaves_ama'),
  deceased('deceased'),
  referred('referred');

  const AdmissionStatus(this.apiValue);

  final String apiValue;

  String get label => apiValue.replaceAll('_', ' ');
}

