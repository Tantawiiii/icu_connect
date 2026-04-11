import 'package:icu_connect/core/network/api_constants.dart';
import 'package:icu_connect/core/network/api_storage_fetch.dart';

/// Removes newlines and spaces often present in bad API payloads.
String cleanRadiologyStoragePath(String rawPath) {
  return rawPath
      .replaceAll('\r', '')
      .replaceAll('\n', '')
      .replaceAll(' ', '')
      .trim();
}

String resolveStorageMediaUrl(String rawPath) {
  final cleanPath = cleanRadiologyStoragePath(rawPath);
  if (cleanPath.isEmpty) return cleanPath;
  if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
    return normalizeApiStorageUrl(cleanPath);
  }
  var rel = cleanPath.startsWith('/') ? cleanPath.substring(1) : cleanPath;
  const storagePrefix = 'storage/';
  if (rel.startsWith(storagePrefix)) {
    rel = rel.substring(storagePrefix.length);
  }

  final base = ApiConstants.imageBaseUrl;
  final b = base.endsWith('/') ? base : '$base/';
  return '$b$rel';
}

/// Whether a local path is treated as video for radiology chips (by extension).
bool isRadiologyPathVideo(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.m4v') ||
      lower.endsWith('.webm') ||
      lower.endsWith('.mkv') ||
      lower.endsWith('.avi');
}
