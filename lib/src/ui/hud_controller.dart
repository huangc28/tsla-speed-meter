import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/data_source.dart';
import '../data/reading.dart';
import '../speed/speed_processor.dart';
import '../trip/mode_controller.dart';
import '../trip/trip_stats.dart';

/// Owns the single data subscription and turns readings into the view state
/// the HUD renders: smoothed speed, fix status, drive/parked mode, trip stats.
class HudController extends ChangeNotifier {
  HudController(
    this._source, {
    SpeedProcessor? processor,
    TripStats? trip,
    ModeController? mode,
  })  : _processor = processor ?? SpeedProcessor(),
        _trip = trip ?? TripStats(),
        _mode = mode ?? ModeController();

  final DataSource _source;
  final SpeedProcessor _processor;
  final TripStats _trip;
  final ModeController _mode;
  StreamSubscription<Reading>? _sub;

  double _speedMs = 0;
  bool _hasFix = false;

  double get speedMs => _speedMs;
  bool get hasFix => _hasFix;
  HudMode get mode => _mode.mode;
  double get tripDistanceM => _trip.distanceM;
  double get tripAvgMs => _trip.avgMs;
  double get tripMaxMs => _trip.maxMs;

  void start() {
    // cancelOnError:false so a transient location error (e.g. permission
    // denied, no fix) degrades to the searching state instead of throwing
    // an unhandled exception and killing the stream.
    _sub = _source.readings().listen(
          _onReading,
          onError: _onError,
          cancelOnError: false,
        );
  }

  void _onError(Object error, StackTrace stackTrace) {
    _hasFix = false;
    notifyListeners();
  }

  void resetTrip() {
    _trip.reset();
    notifyListeners();
  }

  void _onReading(Reading r) {
    _speedMs = _processor.process(r);
    _hasFix = _processor.hasValue;
    if (_hasFix) _trip.add(_speedMs, r.timestamp);
    _mode.update(_speedMs);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
