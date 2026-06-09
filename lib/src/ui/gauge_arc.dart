import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'gauge_geometry.dart';

/// The locked speed arc: thin track ring, cyan active arc to [fraction], a few
/// rim ticks, and a crimson current-value marker. Driven by a 0..1 [fraction]
/// so the parent owns the animation.
class GaugeArc extends StatelessWidget {
  const GaugeArc({
    super.key,
    required this.fraction,
    this.geometry = const GaugeGeometry(),
  });

  /// 0..1 portion of the arc that is filled.
  final double fraction;
  final GaugeGeometry geometry;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _GaugePainter(fraction.clamp(0.0, 1.0), geometry),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.fraction, this.geometry);

  final double fraction;
  final GaugeGeometry geometry;

  static const _track = Color(0xFF1E2A40);
  static const _accent = Color(0xFF2BD4E0);
  static const _tick = Color(0xFF44526A);
  static const _needle = Color(0xFFE8344F);

  static double _rad(double deg) => deg * math.pi / 180.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final startRad = _rad(geometry.startAngleDeg);
    final fullSweepRad = _rad(geometry.sweepDeg);

    final trackPaint = Paint()
      ..color = _track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startRad, fullSweepRad, false, trackPaint);

    if (fraction > 0) {
      final activePaint = Paint()
        ..color = _accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startRad, fullSweepRad * fraction, false, activePaint);
    }

    // rim ticks at 0/60/120/180/240
    final tickPaint = Paint()
      ..color = _tick
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final v in const [0.0, 60.0, 120.0, 180.0, 240.0]) {
      final a = _rad(geometry.tipAngleDeg(v));
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        center + dir * (radius - 4),
        center + dir * (radius + 5),
        tickPaint,
      );
    }

    // crimson current-value marker just inside the band
    final markerAngle = _rad(geometry.startAngleDeg + geometry.sweepDeg * fraction);
    final dir = Offset(math.cos(markerAngle), math.sin(markerAngle));
    final markerPaint = Paint()
      ..color = _needle
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center + dir * (radius - 22),
      center + dir * (radius + 2),
      markerPaint,
    );
    canvas.drawCircle(center + dir * (radius - 10), 4.5, Paint()..color = _needle);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.fraction != fraction || old.geometry != geometry;
}
