import 'package:flutter/material.dart';

import 'src/ui/spike_screen.dart';

/// Dev entry point for the #11 BLE feasibility spike. Run with:
///   flutter run --release -t lib/spike_main.dart -d DEVICE_ID
/// This is a throwaway probe tool, not the shipping HUD (lib/main.dart).
void main() {
  runApp(const MaterialApp(
    title: 'Tesla BLE Spike',
    debugShowCheckedModeBanner: false,
    home: SpikeScreen(),
  ));
}
