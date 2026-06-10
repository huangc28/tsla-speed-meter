/// Pure geometry of the speed arc (locked design): 0 sits at 215°, the arc
/// sweeps -250° clockwise to the max at -35°. Shared by drive and parked.
class GaugeGeometry {
  const GaugeGeometry({
    this.startAngleDeg = 215,
    this.sweepDeg = -250,
    this.maxValue = 240,
  });

  final double startAngleDeg;
  final double sweepDeg;
  final double maxValue;

  /// Fraction of the arc filled for [value], clamped to [0, 1].
  double fraction(double value) => (value / maxValue).clamp(0.0, 1.0);

  /// Angle (degrees) of the current-value marker for [value].
  double tipAngleDeg(double value) => startAngleDeg + sweepDeg * fraction(value);
}
