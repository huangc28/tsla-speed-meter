import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tsla_speed_meter/src/ble/tesla_key_store.dart';

Uint8List _hex(String s) => Uint8List.fromList([
      for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16),
    ]);

String _hexEnc(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('TeslaKeyStore.publicKeyForPrivate', () {
    // Same client keypair used in the protocol.md session-key vector
    // (cross-derived with Python): priv 2538..30db -> uncompressed point.
    test('derives the uncompressed public point Q = d·G', () {
      final pub = TeslaKeyStore.publicKeyForPrivate(_hex(
          '2538cdc29a97c19c1e99a637d6cf4f8c970c118b56ede1e6323e6d162c4b30db'));

      expect(pub, hasLength(65));
      expect(pub.first, 0x04); // uncompressed point marker
      expect(
        _hexEnc(pub),
        '04b2b6bc68c2da0665ce656815594996c62394edd8bea905fe781a754fe6a845'
        'a714330902f225e9269d466e05b349981fda9d85cc23c6fb444aa73b629105dc6e',
      );
    });
  });
}
