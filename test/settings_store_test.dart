import 'package:flutter_test/flutter_test.dart';
import 'package:tsla_speed_meter/src/settings/settings.dart';
import 'package:tsla_speed_meter/src/settings/settings_store.dart';
import 'package:tsla_speed_meter/src/speed/speed_unit.dart';

class _MemStorage implements SettingsStorage {
  Map<String, Object?>? data;
  @override
  Future<Map<String, Object?>?> read() async => data;
  @override
  Future<void> write(Map<String, Object?> d) async => data = Map.of(d);
}

void main() {
  group('SettingsStore', () {
    test('uses defaults when storage is empty', () async {
      final store = SettingsStore(_MemStorage());
      await store.load();
      expect(store.settings.unit, SpeedUnit.kmh);
      expect(store.settings.keepAwake, isTrue);
      expect(store.settings.accent, AccentColor.cyan);
      expect(store.settings.brightness, BrightnessMode.auto);
    });

    test('an update persists and round-trips through a fresh store', () async {
      final storage = _MemStorage();
      final a = SettingsStore(storage);
      await a.load();
      await a.update(a.settings.copyWith(unit: SpeedUnit.mph, mirror: true));

      final b = SettingsStore(storage);
      await b.load();
      expect(b.settings.unit, SpeedUnit.mph);
      expect(b.settings.mirror, isTrue);
    });

    test('a partial stored map merges with defaults', () async {
      final storage = _MemStorage()..data = {'unit': 'mph'};
      final store = SettingsStore(storage);
      await store.load();
      expect(store.settings.unit, SpeedUnit.mph, reason: 'stored value wins');
      expect(store.settings.keepAwake, isTrue, reason: 'missing key keeps default');
    });

    test('an update notifies listeners', () async {
      final store = SettingsStore(_MemStorage());
      await store.load();
      var notified = 0;
      store.addListener(() => notified++);
      await store.update(store.settings.copyWith(mirror: true));
      expect(notified, greaterThan(0));
    });
  });
}
