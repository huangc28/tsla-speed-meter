import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/data_source.dart';
import '../settings/settings.dart';
import '../settings/settings_panel.dart';
import '../settings/settings_store.dart';
import 'drive_screen.dart';

/// Wires settings to the HUD: applies the unit, keep-awake (wakelock) and the
/// day/night brightness, and opens the settings panel from the gear.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.store,
    required this.source,
    this.applyKeepAwake,
  });

  final SettingsStore store;
  final DataSource source;

  /// Side-effect for the keep-awake setting; injectable so widget tests don't
  /// hit the wakelock platform channel. Defaults to the real wakelock.
  final void Function(bool enable)? applyKeepAwake;

  static void _defaultKeepAwake(bool enable) =>
      WakelockPlus.toggle(enable: enable);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    widget.store.addListener(_applyKeepAwake);
    _applyKeepAwake();
  }

  @override
  void dispose() {
    widget.store.removeListener(_applyKeepAwake);
    super.dispose();
  }

  void _applyKeepAwake() {
    (widget.applyKeepAwake ?? AppShell._defaultKeepAwake)(
        widget.store.settings.keepAwake);
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SettingsPanel(store: widget.store)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final s = widget.store.settings;
        Widget hud = DriveScreen(
          source: widget.source,
          unit: s.unit,
          onSettings: _openSettings,
        );
        if (s.mirror) {
          hud = Transform.flip(flipX: true, child: hud);
        }
        // Night dims the surface; day/auto leave it at full brightness.
        final dim = s.brightness == BrightnessMode.night ? 0.28 : 0.0;
        return Stack(
          children: [
            hud,
            if (dim > 0)
              IgnorePointer(
                child: Container(color: Colors.black.withValues(alpha: dim)),
              ),
          ],
        );
      },
    );
  }
}
