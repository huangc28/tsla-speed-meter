enum HudMode { drive, parked }

/// Decides drive vs parked from speed, with a hysteresis band so the HUD does
/// not flip back and forth around a single threshold.
class ModeController {
  ModeController({
    this.parkedBelowMs = 0.5,
    this.driveAboveMs = 2.0,
    HudMode initial = HudMode.parked,
  }) : _mode = initial;

  final double parkedBelowMs;
  final double driveAboveMs;
  HudMode _mode;

  HudMode get mode => _mode;

  HudMode update(double speedMs) {
    if (speedMs >= driveAboveMs) {
      _mode = HudMode.drive;
    } else if (speedMs <= parkedBelowMs) {
      _mode = HudMode.parked;
    }
    // within the band: keep the current mode
    return _mode;
  }
}
