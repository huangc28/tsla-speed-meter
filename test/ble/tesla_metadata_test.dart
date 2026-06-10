import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tsla_speed_meter/src/ble/tesla_metadata.dart';

Uint8List _hex(String s) => Uint8List.fromList([
      for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16),
    ]);

String _hexEnc(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('TeslaSignatureMetadata.serialize', () {
    // Known-answer vector from teslamotors/vehicle-command protocol.md
    // (AES-GCM command-authentication worked example).
    test('serializes the TLV metadata exactly, terminated with 0xff', () {
      final bytes = TeslaSignatureMetadata.serialize(
        signatureType: 0x05, // AES_GCM_PERSONALIZED
        domain: 0x03, // DOMAIN_INFOTAINMENT
        vin: '5YJ30123456789ABC',
        epoch: _hex('4c463f9cc0d3d26906e982ed224adde6'),
        expiresAt: 2655,
        counter: 7,
      );

      expect(
        _hexEnc(bytes),
        '000105010103021135594a333031323334353637383941424303'
        '104c463f9cc0d3d26906e982ed224adde6040400000a5f050400000007ff',
      );
    });
  });
}
