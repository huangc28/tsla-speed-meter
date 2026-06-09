import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsla_speed_meter/src/ui/drive_screen.dart';
import 'package:tsla_speed_meter/src/ui/gauge_arc.dart';

Future<void> _pump(WidgetTester tester, Widget child, {bool reduceMotion = false}) {
  Widget app = MaterialApp(home: child);
  if (reduceMotion) {
    app = MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: child,
      ),
    );
  }
  return tester.pumpWidget(app);
}

void main() {
  testWidgets('renders the speed numeral and unit', (tester) async {
    await _pump(tester, const DriveScreen(speedMs: 25, hasFix: true)); // 90 km/h
    await tester.pump();
    expect(find.text('90'), findsOneWidget);
    expect(find.text('km/h'), findsOneWidget);
  });

  testWidgets('shows the gauge, GPS source chip and settings gear',
      (tester) async {
    await _pump(tester, const DriveScreen(speedMs: 10, hasFix: true));
    await tester.pump();
    expect(find.byType(GaugeArc), findsOneWidget);
    expect(find.text('GPS'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets('reduced motion: arc jumps to the target fraction',
      (tester) async {
    await _pump(tester, const DriveScreen(speedMs: 120 / 3.6, hasFix: true),
        reduceMotion: true); // 120 km/h -> 0.5
    await tester.pump();
    await tester.pump();
    final arc = tester.widget<GaugeArc>(find.byType(GaugeArc));
    expect(arc.fraction, closeTo(0.5, 1e-3));
  });

  testWidgets('no fix: placeholder and searching chip', (tester) async {
    await _pump(tester, const DriveScreen(speedMs: 0, hasFix: false));
    await tester.pump();
    expect(find.text('– –'), findsOneWidget);
    expect(find.textContaining('搜尋'), findsOneWidget);
    expect(find.text('GPS'), findsNothing);
  });

  testWidgets('after a fix, stationary shows a steady 0', (tester) async {
    await _pump(tester, const DriveScreen(speedMs: 0, hasFix: true));
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
    expect(find.text('– –'), findsNothing);
    expect(find.text('GPS'), findsOneWidget);
  });

  testWidgets('landscape: speed-only HUD centers the gauge (no overflow)',
      (tester) async {
    tester.view.physicalSize = const Size(760, 360);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pump(tester, const DriveScreen(speedMs: 25, hasFix: true));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(GaugeArc), findsOneWidget);
    expect(find.text('90'), findsOneWidget);
    final gaugeX = tester.getCenter(find.byType(GaugeArc)).dx;
    expect(gaugeX, closeTo(380, 40), reason: 'gauge stays centered, no right column');
  });

  testWidgets('tapping the settings gear invokes the callback', (tester) async {
    var tapped = 0;
    await _pump(
      tester,
      DriveScreen(speedMs: 10, hasFix: true, onSettings: () => tapped++),
    );
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();
    expect(tapped, 1);
  });
}
