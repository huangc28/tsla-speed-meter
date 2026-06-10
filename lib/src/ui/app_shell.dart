import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/data_source.dart';
import '../settings/settings.dart';
import '../settings/settings_panel.dart';
import '../settings/settings_store.dart';
import '../trip/mode_controller.dart';
import 'drive_screen.dart';
import 'hud_controller.dart';
import 'parked_screen.dart';

/// Wires the data pipeline and settings to the HUD: switches drive/parked by
/// mode, applies the unit, keep-awake (wakelock) and day/night brightness, and
/// opens the settings panel from the gear.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.store,
    required this.source,
    this.applyKeepAwake,
  });

  final SettingsStore store;
  final DataSource source;

  /// Side-effect for keep-awake; injectable so widget tests skip the wakelock
  /// platform channel. Defaults to the real wakelock.
  final void Function(bool enable)? applyKeepAwake;

  static void _defaultKeepAwake(bool enable) =>
      WakelockPlus.toggle(enable: enable);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final HudController _hud;

  @override
  void initState() {
    super.initState();
    _hud = HudController(widget.source)..start();
    widget.store.addListener(_applyKeepAwake);
    _applyKeepAwake();
  }

  @override
  void dispose() {
    widget.store.removeListener(_applyKeepAwake);
    _hud.dispose();
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
      listenable: Listenable.merge([widget.store, _hud]),
      builder: (context, _) {
        final s = widget.store.settings;
        Widget view = _hud.mode == HudMode.drive
            ? DriveScreen(
                speedMs: _hud.speedMs,
                hasFix: _hud.hasFix,
                unit: s.unit,
                onSettings: _openSettings,
              )
            : ParkedScreen(
                tripDistanceM: _hud.tripDistanceM,
                tripAvgMs: _hud.tripAvgMs,
                tripMaxMs: _hud.tripMaxMs,
                unit: s.unit,
                onSettings: _openSettings,
              );
        if (s.mirror) {
          view = Transform.flip(flipX: true, child: view);
        }
        final dim = s.brightness == BrightnessMode.night ? 0.28 : 0.0;
        return Stack(
          children: [
            view,
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
