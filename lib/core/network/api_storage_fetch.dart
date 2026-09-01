import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_constants.dart';
import 'token_storage.dart';

Dio? _mediaDio;

/// Lightweight Dio instance (no auth/base-url interceptors) used only for
/// fetching raw media bytes; headers are set manually per-request instead.
Dio _mediaClient() {
  return _mediaDio ??= Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.bytes,
      validateStatus: (_) => true,
    ),
  );
}

/// Host used for files under [ApiConstants.imageBaseUrl].
String get _apiFileHost => Uri.parse(ApiConstants.imageBaseUrl).host;

/// Converts mistaken `/api/v1/{hospital|admin}/storage/...` URLs to root `/storage/...`.
String normalizeApiStorageUrl(String url) {
  final u = Uri.tryParse(url.trim());
  if (u == null || u.host.isEmpty) return url;
  if (u.host != _apiFileHost) return url;

  var path = u.path;
  const hospitalStorage = '/api/v1/hospital/storage/';
  const adminStorage = '/api/v1/admin/storage/';
  if (path.startsWith(hospitalStorage)) {
    path = '/storage/${path.substring(hospitalStorage.length)}';
  } else if (path.startsWith(adminStorage)) {
    path = '/storage/${path.substring(adminStorage.length)}';
  }
  if (path == u.path) return url;
  return u.replace(path: path).toString();
}

/// Whether [url] should load with [apiStorageAuthHeaders] (same host + `/storage/`).
bool needsAuthenticatedMediaFetch(String url) {
  final normalized = normalizeApiStorageUrl(url);
  final u = Uri.tryParse(normalized.trim());
  if (u == null || u.host.isEmpty || u.host != _apiFileHost) return false;
  return u.path.contains('/storage/');
}

@Deprecated('Use needsAuthenticatedMediaFetch')
bool isApiStorageAbsoluteUrl(String url) => needsAuthenticatedMediaFetch(url);

/// Bearer token for `/storage/` URLs ([fetchHttpImageBytes], video player).
Future<Map<String, String>> apiStorageAuthHeaders() async {
  final t = await TokenStorage.instance.getAccessToken();
  if (t == null || t.isEmpty) return {};
  return {'Authorization': 'Bearer $t'};
}

/// Loads image bytes via [http] (not [Image.network]) with User-Agent + optional Bearer.
Future<Uint8List?> fetchHttpImageBytes(String url) async {
  final fullUrl = normalizeApiStorageUrl(url);
  final uri = Uri.tryParse(fullUrl);
  if (uri == null) return null;

  final headers = <String, String>{
    'User-Agent': 'Mozilla/5.0',
    'Accept': '*/*',
  };
  if (needsAuthenticatedMediaFetch(url)) {
    headers.addAll(await apiStorageAuthHeaders());
  }

  try {
    final response = await _mediaClient().getUri<List<int>>(
      uri,
      options: Options(headers: headers),
    );
    if (kDebugMode) {
      debugPrint('fetchHttpImageBytes status=${response.statusCode} url=$fullUrl');
    }
    if (response.statusCode != 200) return null;
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) return null;
    return Uint8List.fromList(bytes);
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('fetchHttpImageBytes error: $e\n$st');
    }
    return null;
  }
}
