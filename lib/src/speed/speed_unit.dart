/// Display unit for speed. The processor works in m/s; the UI converts here.
enum SpeedUnit {
  kmh(label: 'km/h', factor: 3.6),
  mph(label: 'mph', factor: 2.2369362920544);

  const SpeedUnit({required this.label, required double factor})
      : _factor = factor;

  final String label;
  final double _factor;

  /// Convert a speed in m/s to this unit.
  double fromMs(double ms) => ms * _factor;
}
