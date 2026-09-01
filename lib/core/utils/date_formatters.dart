import '../constants/app_texts.dart';

/// Shared ISO-8601 date/time formatting helpers.
///
/// Consolidates what used to be several near-identical private formatters
/// duplicated across `admission_details_formatters.dart`,
/// `patient_details_screen.dart`, `admin_profile_screen.dart`,
/// `profile_screen.dart`, and `patient_detail_screen.dart`.

/// Returns the date-only portion (before `T`) of an ISO-8601 string, or
/// [fallback] for a null/empty [raw].
String isoDateOnly(String? raw, {String fallback = AppTexts.notAvailable}) {
  if (raw == null || raw.isEmpty) return fallback;
  final t = raw.indexOf('T');
  return t > 0 ? raw.substring(0, t) : raw;
}

/// Same as [isoDateOnly] but returns `null` instead of a fallback string for
/// a null/empty [raw].
String? isoDateOnlyOrNull(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final t = raw.indexOf('T');
  return t > 0 ? raw.substring(0, t) : raw;
}

/// Returns `date HH:MM:SS` extracted directly from an ISO-8601 string
/// (no timezone conversion), with an optional [suffix] appended after the
/// time portion (e.g. a UTC marker).
String isoDateTime(
  String raw, {
  String fallback = AppTexts.notAvailable,
  String suffix = '',
}) {
  if (raw.isEmpty) return fallback;
  final t = raw.indexOf('T');
  if (t <= 0) return raw;
  final date = raw.substring(0, t);
  final time = raw.length > t + 1
      ? raw.substring(t + 1, raw.length > t + 9 ? t + 9 : raw.length)
      : '';
  return time.isEmpty ? date : '$date $time$suffix';
}

/// Parses [iso] as a `DateTime`, converts it to local time, and formats it as
/// `D/M/YYYY  HH:MM`. Returns [iso] unchanged if parsing fails.
String formatLocalDateTime(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    return '${dt.day}/${dt.month}/${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}

/// Formats [d] as `YYYY-MM-DD HH:MM:SS` for sending to the API.
String toSqlDateTime(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')} '
    '${d.hour.toString().padLeft(2, '0')}:'
    '${d.minute.toString().padLeft(2, '0')}:'
    '${d.second.toString().padLeft(2, '0')}';
