import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsla_speed_meter/src/ui/gauge_arc.dart';
import 'package:tsla_speed_meter/src/ui/parked_screen.dart';

void main() {
  testWidgets('shows the trip strip (distance / avg / max) and the gauge',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ParkedScreen(
          tripDistanceM: 128000, // 128 km
          tripAvgMs: 15, // 54 km/h
          tripMaxMs: 36.6667, // 132 km/h
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(GaugeArc), findsOneWidget);
    expect(find.text('本趟'), findsOneWidget);
    expect(find.text('平均'), findsOneWidget);
    expect(find.text('最高'), findsOneWidget);
    expect(find.text('128'), findsOneWidget);
    expect(find.text('54'), findsOneWidget);
    expect(find.text('132'), findsOneWidget);
  });

  testWidgets('tapping the gear invokes the callback', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ParkedScreen(
          tripDistanceM: 0,
          tripAvgMs: 0,
          tripMaxMs: 0,
          onSettings: () => tapped++,
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();
    expect(tapped, 1);
  });
}
