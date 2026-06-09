/// A single sample from a [DataSource]. GPS provides speed/accuracy/position;
/// BLE-sourced fields (battery, range, gear, charge) are added in a later slice.
class Reading {
  final double? speedMs;
  final double? accuracyM;
  final double? latitude;
  final double? longitude;
  final DateTime timestamp;

  const Reading({
    this.speedMs,
    this.accuracyM,
    this.latitude,
    this.longitude,
    required this.timestamp,
  });
}
