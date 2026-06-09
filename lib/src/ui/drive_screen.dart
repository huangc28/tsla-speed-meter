import 'dart:async';

import 'package:flutter/material.dart';

import '../data/data_source.dart';
import '../data/reading.dart';
import '../speed/speed_processor.dart';
import '../speed/speed_unit.dart';

/// Minimal drive HUD: the processed speed numeral over the dark surface.
/// The arc gauge and richer chrome arrive in a later slice.
class DriveScreen extends StatefulWidget {
  const DriveScreen({super.key, required this.source, this.unit = SpeedUnit.kmh});

  final DataSource source;
  final SpeedUnit unit;

  @override
  State<DriveScreen> createState() => _DriveScreenState();
}

class _DriveScreenState extends State<DriveScreen> {
  static const _bg = Color(0xFF0A101C);
  static const _primary = Color(0xFFF2F5FA);
  static const _unitColor = Color(0xFF8A97AE);

  final SpeedProcessor _processor = SpeedProcessor();
  StreamSubscription<Reading>? _sub;
  double _displayMs = 0;

  @override
  void initState() {
    super.initState();
    _sub = widget.source.readings().listen((r) {
      final ms = _processor.process(r);
      if (mounted) setState(() => _displayMs = ms);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.unit.fromMs(_displayMs).round();
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: _primary,
                fontSize: 128,
                fontWeight: FontWeight.w700,
                height: 0.9,
                letterSpacing: -4,
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
    );
  }
}
