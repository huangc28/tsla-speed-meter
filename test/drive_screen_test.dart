import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsla_speed_meter/src/data/data_source.dart';
import 'package:tsla_speed_meter/src/data/reading.dart';
import 'package:tsla_speed_meter/src/ui/drive_screen.dart';

class _FakeSource implements DataSource {
  _FakeSource(this._stream);
  final Stream<Reading> _stream;
  @override
  Stream<Reading> readings() => _stream;
}

void main() {
  testWidgets('renders the processed speed numeral from the data source',
      (tester) async {
    final ctrl = StreamController<Reading>();
    addTearDown(ctrl.close);
    await tester.pumpWidget(
      MaterialApp(home: DriveScreen(source: _FakeSource(ctrl.stream))),
    );

    ctrl.add(Reading(speedMs: 25, accuracyM: 5, timestamp: DateTime.now()));
    await tester.pump();

    // 25 m/s -> 90 km/h
    expect(find.text('90'), findsOneWidget);
    expect(find.text('km/h'), findsOneWidget);
  });
}
