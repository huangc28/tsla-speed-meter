import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'settings_store.dart';

/// [SettingsStorage] backed by shared_preferences (one JSON blob).
class SharedPrefsSettingsStorage implements SettingsStorage {
  static const _key = 'settings';

  @override
  Future<Map<String, Object?>?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return (jsonDecode(raw) as Map).cast<String, Object?>();
  }

  @override
  Future<void> write(Map<String, Object?> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data));
  }
}
