import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'src/data/gps_source.dart';
import 'src/ui/drive_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TslaSpeedMeterApp());
}

class TslaSpeedMeterApp extends StatelessWidget {
  const TslaSpeedMeterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tsla-speed-meter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: const _Bootstrap(),
    );
  }
}

/// Requests foreground location once, then shows the live GPS HUD.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  @override
  void initState() {
    super.initState();
    _requestLocation();
  }

  Future<void> _requestLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    // Denied / weak-signal handling is a later slice; the source simply
    // produces no readings until permission is granted.
  }

  @override
  Widget build(BuildContext context) {
    return DriveScreen(source: GpsSource());
  }
}
