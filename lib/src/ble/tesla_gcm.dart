import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Ciphertext + 16-byte authentication tag from an AES-GCM seal.
class GcmResult {
  final Uint8List ciphertext;
  final Uint8List tag;
  const GcmResult(this.ciphertext, this.tag);
}

/// AES-128-GCM session crypto for Tesla BLE commands
/// (teslamotors/vehicle-command). The GCM associated data is
/// `SHA-256(metadata)`, where `metadata` is the serialized signature TLV
/// (see [TeslaSignatureMetadata]).
class TeslaGcm {
  static const int _tagBytes = 16;

  /// The 16-byte AES-128 session key from [TeslaSession.deriveSessionKey].
  final Uint8List key;

  const TeslaGcm(this.key);

  /// Encrypts [plaintext] with the 12-byte [nonce], authenticating
  /// `SHA-256([metadata])` as associated data.
  GcmResult encrypt(Uint8List nonce, Uint8List plaintext, Uint8List metadata) {
    final out = _run(true, nonce, plaintext, metadata);
    final split = out.length - _tagBytes;
    return GcmResult(
      Uint8List.sublistView(out, 0, split),
      Uint8List.sublistView(out, split),
    );
  }

  /// Decrypts [ciphertext]/[tag] for the given [nonce] and [metadata].
  /// Throws if the tag (or associated data) does not authenticate.
  Uint8List decrypt(
    Uint8List nonce,
    Uint8List ciphertext,
    Uint8List tag,
    Uint8List metadata,
  ) {
    final input = Uint8List(ciphertext.length + tag.length)
      ..setAll(0, ciphertext)
      ..setAll(ciphertext.length, tag);
    return _run(false, nonce, input, metadata);
  }

  Uint8List _run(bool forEncryption, Uint8List nonce, Uint8List input,
      Uint8List metadata) {
    final aad = SHA256Digest().process(metadata);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        forEncryption,
        AEADParameters(KeyParameter(key), _tagBytes * 8, nonce, aad),
      );
    return cipher.process(input);
  }
}
