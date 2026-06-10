import 'package:geolocator/geolocator.dart';

import 'data_source.dart';
import 'reading.dart';

/// Speed-only [DataSource] backed by the phone's GPS.
///
/// The position stream is injectable so the mapping and subscription
/// lifecycle can be tested without real GPS hardware.
class GpsSource implements DataSource {
  GpsSource({Stream<Position> Function()? positionStream})
      : _positionStream = positionStream ?? _defaultPositionStream;

  final Stream<Position> Function() _positionStream;

  @override
  Stream<Reading> readings() => _positionStream().map(_toReading);

  static Reading _toReading(Position p) => Reading(
        speedMs: p.speed,
        accuracyM: p.accuracy,
        latitude: p.latitude,
        longitude: p.longitude,
        timestamp: p.timestamp,
      );

  static Stream<Position> _defaultPositionStream() =>
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );
}
