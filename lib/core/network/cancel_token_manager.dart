import 'package:dio/dio.dart';

/// Centrally manages [CancelToken]s so any in-flight request can be cancelled
/// individually (by tag) or all at once (e.g., on logout or screen dispose).
class CancelTokenManager {
  CancelTokenManager._();

  static final CancelTokenManager _instance = CancelTokenManager._();
  static CancelTokenManager get instance => _instance;

  final Map<String, CancelToken> _tokens = {};

  /// Returns an existing token for [tag] or creates a new one.
  CancelToken getToken(String tag) {
    if (_tokens[tag] == null || _tokens[tag]!.isCancelled) {
      _tokens[tag] = CancelToken();
    }
    return _tokens[tag]!;
  }

  /// Cancels the token registered under [tag] and removes it.
  void cancel(String tag, [String? reason]) {
    _tokens[tag]?.cancel(reason ?? 'Request cancelled: $tag');
    _tokens.remove(tag);
  }

  /// Cancels every registered token (useful on logout or app-level teardown).
  void cancelAll([String? reason]) {
    for (final entry in _tokens.entries) {
      entry.value.cancel(reason ?? 'All requests cancelled');
    }
    _tokens.clear();
  }

  /// Removes a token after it has completed normally (no cancel needed).
  void dispose(String tag) => _tokens.remove(tag);
}
