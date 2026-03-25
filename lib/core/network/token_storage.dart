import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage._();

  static final TokenStorage _instance = TokenStorage._();
  static TokenStorage get instance => _instance;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// In-memory fallback used when the native plugin is not yet available
  /// (e.g. before a full cold-restart after adding the plugin).
  final Map<String, String> _memCache = {};

  // ── Keys ──────────────────────────────────────────────────────────────────
  static const _keyAccessToken = 'icu_access_token';
  static const _keyRefreshToken = 'icu_refresh_token';
  static const _keyUserRole = 'icu_user_role';
  static const _keyDoctorDrawerName = 'icu_doctor_drawer_name';
  static const _keyDoctorDrawerRole = 'icu_doctor_drawer_role';

  // ── Access token ──────────────────────────────────────────────────────────
  Future<void> saveAccessToken(String token) =>
      _write(_keyAccessToken, token);

  Future<String?> getAccessToken() => _read(_keyAccessToken);

  // ── Refresh token ─────────────────────────────────────────────────────────
  Future<void> saveRefreshToken(String token) =>
      _write(_keyRefreshToken, token);

  Future<String?> getRefreshToken() => _read(_keyRefreshToken);

  // ── User role (admin / hospital) ──────────────────────────────────────────
  Future<void> saveUserRole(String role) => _write(_keyUserRole, role);

  Future<String?> getUserRole() => _read(_keyUserRole);

  /// Doctor app drawer header (name + role from login / profile).
  Future<void> saveDoctorDrawerInfo({
    required String name,
    required String role,
  }) async {
    await _write(_keyDoctorDrawerName, name);
    await _write(_keyDoctorDrawerRole, role);
  }

  Future<String?> getDoctorDrawerName() => _read(_keyDoctorDrawerName);

  Future<String?> getDoctorDrawerRole() => _read(_keyDoctorDrawerRole);

  // ── Clear all (logout) ────────────────────────────────────────────────────
  Future<void> clearAll() async {
    _memCache.clear();
    try {
      await _storage.deleteAll();
    } on MissingPluginException {
      // plugin not linked yet — in-memory cache already cleared above
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _write(String key, String value) async {
    _memCache[key] = value;
    try {
      await _storage.write(key: key, value: value);
    } on MissingPluginException {
      // native plugin unavailable — value is kept in _memCache
    }
  }

  Future<String?> _read(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (value != null) _memCache[key] = value;
      return value;
    } on MissingPluginException {
      return _memCache[key];
    }
  }
}
