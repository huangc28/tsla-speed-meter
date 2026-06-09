import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsla_speed_meter/src/settings/settings_store.dart';
import 'package:tsla_speed_meter/src/settings/settings_panel.dart';
import 'package:tsla_speed_meter/src/speed/speed_unit.dart';

class _MemStorage implements SettingsStorage {
  Map<String, Object?>? data;
  @override
  Future<Map<String, Object?>?> read() async => data;
  @override
  Future<void> write(Map<String, Object?> d) async => data = Map.of(d);
}

Future<SettingsStore> _loadedStore() async {
  final s = SettingsStore(_MemStorage());
  await s.load();
  return s;
}

void main() {
  testWidgets('tapping mph updates the unit in the store', (tester) async {
    final store = await _loadedStore();
    await tester.pumpWidget(MaterialApp(home: SettingsPanel(store: store)));

    expect(store.settings.unit, SpeedUnit.kmh);
    await tester.tap(find.text('mph'));
    await tester.pump();
    expect(store.settings.unit, SpeedUnit.mph);
  });

  testWidgets('the active accent is marked with a non-color check indicator',
      (tester) async {
    final store = await _loadedStore();
    await tester.pumpWidget(MaterialApp(home: SettingsPanel(store: store)));

    // Default accent is cyan; exactly one swatch carries the check.
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('controls meet the 44pt minimum touch target', (tester) async {
    final store = await _loadedStore();
    await tester.pumpWidget(MaterialApp(home: SettingsPanel(store: store)));

    final size = tester.getSize(find.byKey(const ValueKey('accent-cyan')));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });
}
