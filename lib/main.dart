import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'src/data/gps_source.dart';
import 'src/settings/settings_store.dart';
import 'src/settings/shared_prefs_settings_storage.dart';
import 'src/ui/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = SettingsStore(SharedPrefsSettingsStorage());
  await store.load();
  runApp(TslaSpeedMeterApp(store: store));
}

class TslaSpeedMeterApp extends StatelessWidget {
  const TslaSpeedMeterApp({super.key, required this.store});

  final SettingsStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tsla-speed-meter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: _Bootstrap(store: store),
    );
  }
}

/// Requests foreground location once, then shows the live HUD.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap({required this.store});

  final SettingsStore store;

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
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(store: widget.store, source: GpsSource());
  }
}
