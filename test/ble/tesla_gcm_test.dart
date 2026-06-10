import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tsla_speed_meter/src/ble/tesla_gcm.dart';

Uint8List _hex(String s) => Uint8List.fromList([
      for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16),
    ]);

String _hexEnc(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

void main() {
  // Known-answer vector from teslamotors/vehicle-command protocol.md AES-GCM
  // worked example. AAD = SHA256(metadata); cross-validated with Python.
  final key = _hex('1b2fce19967b79db696f909cff89ea9a');
  final nonce = _hex('dbf79447fa156674dae1caed');
  final plaintext = _hex('120452020801');
  final metadata = _hex(
      '000105010103021135594a333031323334353637383941424303'
      '104c463f9cc0d3d26906e982ed224adde6040400000a5f050400000007ff');

  group('TeslaGcm', () {
    test('encrypt reproduces the protocol.md ciphertext and tag', () {
      final result = TeslaGcm(key).encrypt(nonce, plaintext, metadata);

      expect(_hexEnc(result.ciphertext), '38038e8c0f2e');
      expect(_hexEnc(result.tag), '8e128da165f162f4d7d2c8da866cf82a');
    });

    test('decrypt round-trips the ciphertext back to plaintext', () {
      final r = TeslaGcm(key).encrypt(nonce, plaintext, metadata);
      final back = TeslaGcm(key).decrypt(nonce, r.ciphertext, r.tag, metadata);

      expect(_hexEnc(back), _hexEnc(plaintext));
    });

    test('decrypt rejects a tampered tag', () {
      final r = TeslaGcm(key).encrypt(nonce, plaintext, metadata);
      final badTag = Uint8List.fromList(r.tag)..[0] ^= 0xff;

      expect(
        () => TeslaGcm(key).decrypt(nonce, r.ciphertext, badTag, metadata),
        throwsA(isA<Exception>()),
      );
    });
  });
}
