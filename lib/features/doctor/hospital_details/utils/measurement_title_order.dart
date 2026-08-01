import 'package:icu_connect/features/superAdmin/patients/models/patient_admission_models.dart';

/// Canonical row order for labs and vitals tables in admission screens.
class MeasurementTitleOrder {
  MeasurementTitleOrder._();

  static const labOrder = <String>[
    'hgb',
    'tlc',
    'plt',
    'ph',
    'pco2',
    'hco3',
    'lac',
    'na',
    'k',
    'ca',
    'urea',
    'creat',
    'ast',
    'alt',
  ];

  static const vitalOrder = <String>[
    'gcs',
    'bpsys',
    'bpdia',
    'cvp',
    'hr',
    'rr',
    'spo2',
    'o2support',
    'temp',
    'uop',
  ];

  static const _aliases = <String, String>{
    'creatinine': 'creat',
    'hemoglobin': 'hgb',
    'wbc': 'tlc',
    'whitebloodcell': 'tlc',
    'whitebloodcells': 'tlc',
  };

  static String canonicalKey(String title) {
    final normalized = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    return _aliases[normalized] ?? normalized;
  }

  static int _indexFor(String title, List<String> order) {
    final key = canonicalKey(title);
    final index = order.indexOf(key);
    return index >= 0 ? index : order.length;
  }

  static List<MeasurementTitleModel> sortLabs(
    List<MeasurementTitleModel> titles,
  ) {
    return _sort(titles, labOrder);
  }

  static List<MeasurementTitleModel> sortVitals(
    List<MeasurementTitleModel> titles,
  ) {
    return _sort(titles, vitalOrder);
  }

  static List<MeasurementTitleModel> _sort(
    List<MeasurementTitleModel> titles,
    List<String> order,
  ) {
    final sorted = List<MeasurementTitleModel>.from(titles);
    sorted.sort((a, b) {
      final ai = _indexFor(a.title, order);
      final bi = _indexFor(b.title, order);
      if (ai != bi) return ai.compareTo(bi);
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return sorted;
  }
}
