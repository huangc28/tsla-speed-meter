import 'dart:convert';

import 'package:pointycastle/export.dart';

/// Tesla vehicle BLE GATT identifiers and helpers
/// (teslamotors/vehicle-command pkg/connector/ble).
class TeslaBle {
  /// GATT service the vehicle exposes.
  static const String serviceUuid = '00000211-b2d1-43f0-9b88-960cebf8b91e';

  /// Characteristic the client writes requests to (to vehicle).
  static const String txCharUuid = '00000212-b2d1-43f0-9b88-960cebf8b91e';

  /// Characteristic the client subscribes to for responses (from vehicle).
  static const String rxCharUuid = '00000213-b2d1-43f0-9b88-960cebf8b91e';

  /// Max single message length the vehicle accepts/returns.
  static const int maxMessageLength = 1024;

  /// The BLE advertised local name for a given [vin]:
  /// `"S" + hex(SHA1(vin)[:8]) + "C"` (16 hex chars between S and C).
  static String localNameForVin(String vin) {
    final digest = SHA1Digest().process(ascii.encode(vin));
    final hex =
        digest.take(8).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'S${hex}C';
  }
}
