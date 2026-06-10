/// Drive gear reported by the vehicle cluster.
enum Gear { park, reverse, neutral, drive, unknown }

/// A single sample from a [DataSource]. GPS provides speed/accuracy/position;
/// BLE (Tesla) provides speed plus the cluster fields (gear, battery, range,
/// power). Every field is nullable so one [Reading] type can carry either
/// source, and the composite source can merge them.
class Reading {
  final double? speedMs;
  final double? accuracyM;
  final double? latitude;
  final double? longitude;

  // Cluster fields — BLE only.
  final Gear? gear;
  final int? batteryPercent;
  final double? rangeMiles;
  final int? powerKw;

  final DateTime timestamp;

  const Reading({
    this.speedMs,
    this.accuracyM,
    this.latitude,
    this.longitude,
    this.gear,
    this.batteryPercent,
    this.rangeMiles,
    this.powerKw,
    required this.timestamp,
  });
}
