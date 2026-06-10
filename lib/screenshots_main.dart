// Dev-only harness: renders Goal 1 views with sample data so they can be
// screenshotted (the real app shows "searching" without a live GPS fix).
// Not shipped. Run: flutter build web -t lib/screenshots_main.dart
import 'package:flutter/material.dart';

import 'src/settings/settings_store.dart';
import 'src/ui/drive_screen.dart';
import 'src/ui/parked_screen.dart';
import 'src/settings/settings_panel.dart';

class _MemStorage implements SettingsStorage {
  @override
  Future<Map<String, Object?>?> read() async => null;
  @override
  Future<void> write(Map<String, Object?> d) async {}
}

void main() => runApp(const _Gallery());

class _Gallery extends StatelessWidget {
  const _Gallery();

  @override
  Widget build(BuildContext context) {
    final store = SettingsStore(_MemStorage());
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: Scaffold(
        backgroundColor: const Color(0xFF05080E),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Wrap(
            spacing: 36,
            runSpacing: 40,
            children: [
              _frame('Drive · 88 km/h', 320, 692,
                  const DriveScreen(speedMs: 24.444, hasFix: true)),
              _frame('Parked · trip stats', 320, 692,
                  const ParkedScreen(
                      tripDistanceM: 128000, tripAvgMs: 15, tripMaxMs: 36.6667)),
              _frame('Waiting · no GPS fix', 320, 692,
                  const DriveScreen(speedMs: 0, hasFix: false)),
              _frame('Settings', 320, 692, SettingsPanel(store: store)),
              _frame('Parked · landscape (dash-mount)', 640, 320,
                  const ParkedScreen(
                      tripDistanceM: 128000, tripAvgMs: 15, tripMaxMs: 36.6667)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _frame(String label, double w, double h, Widget screen) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            boxShadow: const [
              BoxShadow(color: Color(0xFF11161F), blurRadius: 0, spreadRadius: 8),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: SizedBox(
              width: w,
              height: h,
              child: MediaQuery(
                data: MediaQueryData(size: Size(w, h)),
                child: screen,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(label,
            style: const TextStyle(
                color: Color(0xFFAEBCD4),
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
