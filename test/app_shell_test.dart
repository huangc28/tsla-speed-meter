import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsla_speed_meter/src/data/data_source.dart';
import 'package:tsla_speed_meter/src/data/reading.dart';
import 'package:tsla_speed_meter/src/settings/settings_store.dart';
import 'package:tsla_speed_meter/src/ui/app_shell.dart';
import 'package:tsla_speed_meter/src/ui/drive_screen.dart';

class _FakeSource implements DataSource {
  @override
  Stream<Reading> readings() => const Stream.empty();
}

class _MemStorage implements SettingsStorage {
  Map<String, Object?>? data;
  @override
  Future<Map<String, Object?>?> read() async => data;
  @override
  Future<void> write(Map<String, Object?> d) async => data = Map.of(d);
}

Future<SettingsStore> _store({bool mirror = false, bool keepAwake = true}) async {
  final s = SettingsStore(_MemStorage());
  await s.load();
  await s.update(s.settings.copyWith(mirror: mirror, keepAwake: keepAwake));
  return s;
}

bool _isFlipped(WidgetTester tester) {
  final t = tester.widgetList<Transform>(
    find.ancestor(of: find.byType(DriveScreen), matching: find.byType(Transform)),
  );
  return t.any((w) => w.transform.entry(0, 0) == -1.0);
}

void main() {
  testWidgets('mirror off: HUD is not flipped', (tester) async {
    final store = await _store(mirror: false);
    await tester.pumpWidget(MaterialApp(
      home: AppShell(store: store, source: _FakeSource(), applyKeepAwake: (_) {}),
    ));
    expect(_isFlipped(tester), isFalse);
  });

  testWidgets('mirror on: HUD is flipped horizontally', (tester) async {
    final store = await _store(mirror: true);
    await tester.pumpWidget(MaterialApp(
      home: AppShell(store: store, source: _FakeSource(), applyKeepAwake: (_) {}),
    ));
    expect(_isFlipped(tester), isTrue);
  });

  testWidgets('toggling mirror at runtime flips the HUD', (tester) async {
    final store = await _store(mirror: false);
    await tester.pumpWidget(MaterialApp(
      home: AppShell(store: store, source: _FakeSource(), applyKeepAwake: (_) {}),
    ));
    expect(_isFlipped(tester), isFalse);

    await store.update(store.settings.copyWith(mirror: true));
    await tester.pump();
    expect(_isFlipped(tester), isTrue);
  });

  testWidgets('keep-awake setting is applied on launch', (tester) async {
    final store = await _store(keepAwake: true);
    final calls = <bool>[];
    await tester.pumpWidget(MaterialApp(
      home: AppShell(store: store, source: _FakeSource(), applyKeepAwake: calls.add),
    ));
    expect(calls, contains(true));
  });
}
