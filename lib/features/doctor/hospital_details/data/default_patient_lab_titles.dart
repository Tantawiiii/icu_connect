import 'package:icu_connect/core/utils/measurement_title_form_helpers.dart';

/// Patient lab titles created automatically when adding a labs column.
class DefaultPatientLabTitles {
  DefaultPatientLabTitles._();

  static const customSpO2 = MeasurementTitleFormValues(
    title: 'Custom SpO2',
    unit: '%',
    valueType: 'numeric',
    normalRangeMin: 95,
    normalRangeMax: 100,
  );

  static const presets = <MeasurementTitleFormValues>[customSpO2];
}
