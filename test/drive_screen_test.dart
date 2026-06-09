import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsla_speed_meter/src/data/data_source.dart';
import 'package:tsla_speed_meter/src/data/reading.dart';
import 'package:tsla_speed_meter/src/ui/drive_screen.dart';
import 'package:tsla_speed_meter/src/ui/gauge_arc.dart';

class _FakeSource implements DataSource {
  _FakeSource(this._stream);
  final Stream<Reading> _stream;
  @override
  Stream<Reading> readings() => _stream;
}

Reading _r(double speedMs) =>
    Reading(speedMs: speedMs, accuracyM: 5, timestamp: DateTime.now());

void main() {
  testWidgets('renders the processed speed numeral from the data source',
      (tester) async {
    final ctrl = StreamController<Reading>();
    addTearDown(ctrl.close);
    await tester.pumpWidget(
      MaterialApp(home: DriveScreen(source: _FakeSource(ctrl.stream))),
    );

    ctrl.add(_r(25)); // 25 m/s -> 90 km/h
    await tester.pump();

    expect(find.text('90'), findsOneWidget);
    expect(find.text('km/h'), findsOneWidget);
  });

  testWidgets('shows the gauge, GPS source chip and settings gear',
      (tester) async {
    final ctrl = StreamController<Reading>();
    addTearDown(ctrl.close);
    await tester.pumpWidget(
      MaterialApp(home: DriveScreen(source: _FakeSource(ctrl.stream))),
    );

    ctrl.add(_r(10));
    await tester.pump();

    expect(find.byType(GaugeArc), findsOneWidget);
    expect(find.text('GPS'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets('reduced motion: arc jumps to the target fraction without easing',
      (tester) async {
    final ctrl = StreamController<Reading>();
    addTearDown(ctrl.close);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: DriveScreen(source: _FakeSource(ctrl.stream)),
        ),
      ),
    );

    ctrl.add(_r(120 / 3.6)); // 120 km/h -> fraction 0.5
    await tester.pump(); // setState from reading
    await tester.pump(); // tween (instant under disableAnimations)

    final arc = tester.widget<GaugeArc>(find.byType(GaugeArc));
    expect(arc.fraction, closeTo(0.5, 1e-3));
  });

  testWidgets('no fix yet: shows the placeholder and the searching chip',
      (tester) async {
    final ctrl = StreamController<Reading>();
    addTearDown(ctrl.close);
    await tester.pumpWidget(
      MaterialApp(home: DriveScreen(source: _FakeSource(ctrl.stream))),
    );
    await tester.pump();

    expect(find.text('– –'), findsOneWidget);
    expect(find.textContaining('搜尋'), findsOneWidget);
    expect(find.text('GPS'), findsNothing);
  });

  testWidgets('after a fix, stationary shows a steady 0 (not the placeholder)',
      (tester) async {
    final ctrl = StreamController<Reading>();
    addTearDown(ctrl.close);
    await tester.pumpWidget(
      MaterialApp(home: DriveScreen(source: _FakeSource(ctrl.stream))),
    );

    ctrl.add(_r(0)); // good fix, stationary
    await tester.pump();

    expect(find.text('0'), findsOneWidget);
    expect(find.text('– –'), findsNothing);
    expect(find.text('GPS'), findsOneWidget);
  });

  testWidgets('a low-accuracy-only stream stays in the searching state',
      (tester) async {
    final ctrl = StreamController<Reading>();
    addTearDown(ctrl.close);
    await tester.pumpWidget(
      MaterialApp(home: DriveScreen(source: _FakeSource(ctrl.stream))),
    );

    ctrl.add(Reading(speedMs: 30, accuracyM: 100, timestamp: DateTime.now()));
    await tester.pump();

    expect(find.text('– –'), findsOneWidget);
  });
}
