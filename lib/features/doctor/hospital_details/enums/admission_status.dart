enum AdmissionStatus {
  admitted('admitted'),
  discharged('discharged');
  // active('active'),
  // inactive('inactive'),

  // leavesAma('leaves_ama'),
  // deceased('deceased'),
  // referred('referred');

  const AdmissionStatus(this.apiValue);

  final String apiValue;

  String get label => apiValue.replaceAll('_', ' ');
}

