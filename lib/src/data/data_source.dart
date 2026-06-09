import 'reading.dart';

/// The seam every source implements: GPS now, Tesla BLE / composite later.
/// The UI consumes [readings] and never depends on the concrete source.
abstract class DataSource {
  /// A live stream of [Reading]s. Cancel the subscription to stop.
  Stream<Reading> readings();
}
