import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Tesla vehicle BLE session cryptography (portable core, no BLE/Flutter deps).
///
/// Derivation follows teslamotors/vehicle-command (pkg/protocol/protocol.md):
/// over NIST P-256, the shared AES-128-GCM key is
/// `K = SHA1(BIG_ENDIAN(Sx, 32))[:16]`, where `Sx` is the X coordinate of the
/// ECDH shared point between the client private key and the vehicle public key.
class TeslaSession {
  /// Derives the 16-byte AES-128-GCM session key shared with the vehicle.
  ///
  /// [clientPrivateKey] is the 32-byte big-endian private scalar.
  /// [vehiclePublicKey] is the 65-byte uncompressed point (`0x04 || X || Y`).
  static Uint8List deriveSessionKey({
    required Uint8List clientPrivateKey,
    required Uint8List vehiclePublicKey,
  }) {
    final domain = ECDomainParameters('secp256r1');
    final priv = ECPrivateKey(_bytesToBigInt(clientPrivateKey), domain);
    final pub = ECPublicKey(domain.curve.decodePoint(vehiclePublicKey), domain);

    final agreement = ECDHBasicAgreement()..init(priv);
    final sharedX = agreement.calculateAgreement(pub); // Sx as a BigInt

    final sxBytes = _bigIntToBytes(sharedX, 32);
    final digest = SHA1Digest().process(sxBytes);
    return Uint8List.fromList(digest.sublist(0, 16));
  }
}

BigInt _bytesToBigInt(Uint8List bytes) {
  var result = BigInt.zero;
  for (final byte in bytes) {
    result = (result << 8) | BigInt.from(byte);
  }
  return result;
}

/// Big-endian, left-padded to exactly [length] bytes (matches Go's FillBytes).
Uint8List _bigIntToBytes(BigInt value, int length) {
  final out = Uint8List(length);
  var v = value;
  final mask = BigInt.from(0xff);
  for (var i = length - 1; i >= 0; i--) {
    out[i] = (v & mask).toInt();
    v = v >> 8;
  }
  return out;
}
