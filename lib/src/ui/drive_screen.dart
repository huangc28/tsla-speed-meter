import 'dart:async';

import 'package:flutter/material.dart';

import '../data/data_source.dart';
import '../data/reading.dart';
import '../speed/speed_processor.dart';
import '../speed/speed_unit.dart';
import 'gauge_arc.dart';
import 'gauge_geometry.dart';

/// Drive HUD: the speed numeral over the arc gauge, with the source-status
/// chip and a settings gear. The gauge fraction eases toward the live value
/// (instant under reduced-motion).
class DriveScreen extends StatefulWidget {
  const DriveScreen({
    super.key,
    required this.source,
    this.unit = SpeedUnit.kmh,
    this.onSettings,
  });

  final DataSource source;
  final SpeedUnit unit;
  final VoidCallback? onSettings;

  @override
  State<DriveScreen> createState() => _DriveScreenState();
}

class _DriveScreenState extends State<DriveScreen> {
  static const _bg = Color(0xFF0A101C);
  static const _primary = Color(0xFFF2F5FA);
  static const _unitColor = Color(0xFF8A97AE);
  static const _gpsFix = Color(0xFF3DE0A8);
  static const _gpsSearch = Color(0xFFF5B53C);
  static const _gpsSearchText = Color(0xFFD7A23E);
  static const _tertiary = Color(0xFF6E7E8C);
  static const _waitingNumeral = Color(0xFF46505E);

  static const _geometry = GaugeGeometry();

  final SpeedProcessor _processor = SpeedProcessor();
  StreamSubscription<Reading>? _sub;
  double _displayMs = 0;
  bool _hasFix = false;

  @override
  void initState() {
    super.initState();
    _sub = widget.source.readings().listen((r) {
      final ms = _processor.process(r);
      if (mounted) {
        setState(() {
          _displayMs = ms;
          _hasFix = _processor.hasValue;
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final searching = !_hasFix;
    final kmh = SpeedUnit.kmh.fromMs(_displayMs);
    final targetFraction = searching ? 0.0 : _geometry.fraction(kmh);
    final numeralText = searching ? '– –' : '${widget.unit.fromMs(_displayMs).round()}';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(top: 12, left: 22, child: _sourceChip(searching)),
            Positioned(
              top: 8,
              right: 18,
              child: GestureDetector(
                onTap: widget.onSettings,
                child: const Padding(
                  padding: EdgeInsets.all(11), // >=44pt hit area
                  child: Icon(Icons.settings, color: Color(0xFF3C5160), size: 22),
                ),
              ),
            ),
            Center(
              child: SizedBox(
                width: 246,
                height: 246,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: targetFraction),
                  duration:
                      reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
                  curve: Curves.easeOutQuart,
                  builder: (_, f, _) =>
                      GaugeArc(fraction: f, geometry: _geometry, active: !searching),
                ),
              ),
            ),
            // Numeral overlays the gauge as a sibling, so it is sized to its
            // content and never clipped by the gauge box.
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    numeralText,
                    style: TextStyle(
                      color: searching ? _waitingNumeral : _primary,
                      fontSize: searching ? 104 : 128,
                      fontWeight: FontWeight.w700,
                      height: 0.9,
                      letterSpacing: searching ? 6 : -4,
                    ),
                  ),
                  Text(
                    widget.unit.label,
                    style: const TextStyle(
                      color: _unitColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceChip(bool searching) {
    final dotColor = searching ? _gpsSearch : _gpsFix;
    final label = searching ? '搜尋 GPS 訊號…' : 'GPS';
    final labelColor = searching ? _gpsSearchText : _tertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }
}
