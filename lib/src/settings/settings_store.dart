import 'package:flutter/foundation.dart';

import 'settings.dart';

/// Persistence boundary, injectable so the store is testable without
/// platform storage.
abstract class SettingsStorage {
  Future<Map<String, Object?>?> read();
  Future<void> write(Map<String, Object?> data);
}

/// Holds the current [Settings], loads/persists them through [SettingsStorage],
/// and notifies listeners on change.
class SettingsStore extends ChangeNotifier {
  SettingsStore(this._storage);

  final SettingsStorage _storage;
  Settings _settings = const Settings();

  Settings get settings => _settings;

  Future<void> load() async {
    final stored = await _storage.read();
    if (stored != null) {
      _settings = Settings.fromMap(stored);
      notifyListeners();
    }
  }

  Future<void> update(Settings next) async {
    _settings = next;
    notifyListeners();
    await _storage.write(next.toMap());
  }
}
