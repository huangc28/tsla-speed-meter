import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Generates and persists the client's P-256 "phone key" used to enroll with
/// and authenticate to the vehicle. The private scalar is stored in
/// SharedPreferences so the same key survives app restarts (enrollment is
/// one-time). Persistence is untested (device-only); the pure point math is
/// covered by tests.
class TeslaKeyStore {
  static const String _prefKey = 'tesla_ble_private_key_hex';

  /// 32-byte big-endian private scalar.
  final Uint8List privateKey;

  /// 65-byte uncompressed public point (`0x04 || X || Y`).
  final Uint8List publicKey;

  TeslaKeyStore._(this.privateKey, this.publicKey);

  static Future<TeslaKeyStore> loadOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKey);
    final priv = stored != null ? _hexToBytes(stored) : _generatePrivateScalar();
    if (stored == null) {
      await prefs.setString(_prefKey, _bytesToHex(priv));
    }
    return TeslaKeyStore._(priv, publicKeyForPrivate(priv));
  }

  /// Derives the uncompressed public point for a private scalar: `Q = d·G`.
  static Uint8List publicKeyForPrivate(Uint8List privateKey) {
    final domain = ECDomainParameters('secp256r1');
    final d = _bytesToBigInt(privateKey);
    final q = (domain.G * d)!;
    return Uint8List.fromList(q.getEncoded(false));
  }

  static Uint8List _generatePrivateScalar() {
    final keyParams = ECKeyGeneratorParameters(ECDomainParameters('secp256r1'));
    final rng = FortunaRandom();
    final seed = Uint8List.fromList(
        List<int>.generate(32, (_) => Random.secure().nextInt(256)));
    rng.seed(KeyParameter(seed));
    final generator = ECKeyGenerator()
      ..init(ParametersWithRandom(keyParams, rng));
    final pair = generator.generateKeyPair();
    final d = (pair.privateKey as ECPrivateKey).d!;
    return _bigIntToBytes(d, 32);
  }
}

BigInt _bytesToBigInt(Uint8List bytes) {
  var result = BigInt.zero;
  for (final byte in bytes) {
    result = (result << 8) | BigInt.from(byte);
  }
  return result;
}

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

Uint8List _hexToBytes(String s) => Uint8List.fromList([
      for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16),
    ]);

String _bytesToHex(Uint8List b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
