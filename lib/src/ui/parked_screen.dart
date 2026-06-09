import 'package:flutter/material.dart';

import '../speed/speed_unit.dart';
import 'gauge_arc.dart';
import 'gauge_geometry.dart';

/// Parked HUD view (GPS-only): the resting gauge at 0, a trip stat strip
/// (distance / avg / max) and the date/time pill. Battery/gear are BLE-only
/// and arrive in a later slice.
class ParkedScreen extends StatelessWidget {
  const ParkedScreen({
    super.key,
    required this.tripDistanceM,
    required this.tripAvgMs,
    required this.tripMaxMs,
    this.unit = SpeedUnit.kmh,
    this.onSettings,
  });

  final double tripDistanceM;
  final double tripAvgMs;
  final double tripMaxMs;
  final SpeedUnit unit;
  final VoidCallback? onSettings;

  static const _bg = Color(0xFF0A101C);
  static const _primary = Color(0xFFF2F5FA);
  static const _unitColor = Color(0xFF8A97AE);
  static const _tertiary = Color(0xFF6E7E8C);
  static const _secondary = Color(0xFFAEBCD4);
  static const _divider = Color(0xFF1A2433);
  static const _accentText = Color(0xFF6FD8E2);
  static const _geometry = GaugeGeometry();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(top: 12, left: 22, child: _Chip()),
            Positioned(
              top: 8,
              right: 18,
              child: GestureDetector(
                onTap: onSettings,
                child: const Padding(
                  padding: EdgeInsets.all(11),
                  child: Icon(Icons.settings, color: Color(0xFF3C5160), size: 22),
                ),
              ),
            ),
            const Center(
              child: SizedBox(
                width: 246,
                height: 246,
                child: GaugeArc(fraction: 0, active: false, geometry: _geometry),
              ),
            ),
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('0',
                      style: TextStyle(
                          color: _primary,
                          fontSize: 100,
                          fontWeight: FontWeight.w700,
                          height: 0.9,
                          letterSpacing: -3)),
                  Text('km/h',
                      style: TextStyle(
                          color: _unitColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2.5)),
                ],
              ),
            ),
            Positioned(left: 26, right: 26, bottom: 96, child: _tripStrip()),
            Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: Center(child: _pill(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tripStrip() {
    final distanceKm = (tripDistanceM / 1000).round();
    final avg = SpeedUnit.kmh.fromMs(tripAvgMs).round();
    final max = SpeedUnit.kmh.fromMs(tripMaxMs).round();
    return Row(
      children: [
        _cell('本趟', '$distanceKm', 'km'),
        _vrule(),
        _cell('平均', '$avg', 'km/h'),
        _vrule(),
        _cell('最高', '$max', 'km/h'),
      ],
    );
  }

  Widget _vrule() => Container(width: 1, height: 34, color: _divider);

  Widget _cell(String k, String v, String u) => Expanded(
        child: Column(
          children: [
            Text(k,
                style: const TextStyle(
                    color: _tertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(v,
                    style: const TextStyle(
                        color: _secondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 2),
                Text(u,
                    style: const TextStyle(
                        color: Color(0xFF5A6675),
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      );

  Widget _pill(BuildContext context) {
    final now = TimeOfDay.now().format(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C5A66)),
      ),
      child: Text(now,
          style: const TextStyle(
              color: _accentText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8)),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip();
  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 8,
          height: 8,
          child: DecoratedBox(
              decoration:
                  BoxDecoration(color: Color(0xFF3DE0A8), shape: BoxShape.circle)),
        ),
        SizedBox(width: 7),
        Text('GPS',
            style: TextStyle(
                color: Color(0xFF6E7E8C),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.6)),
      ],
    );
  }
}
