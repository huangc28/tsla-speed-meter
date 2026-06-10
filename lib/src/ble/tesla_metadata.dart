import 'dart:convert';
import 'dart:typed_data';

/// TLV tag bytes for Tesla signature metadata (teslamotors/vehicle-command,
/// `Tag` enum in signatures.proto / protocol.md).
class MetadataTag {
  static const int signatureType = 0x00;
  static const int domain = 0x01;
  static const int personalization = 0x02; // VIN
  static const int epoch = 0x03;
  static const int expiresAt = 0x04;
  static const int counter = 0x05;
  static const int flags = 0x06;
  static const int end = 0xff;
}

/// Serializes the AES-GCM signature metadata that Tesla hashes (SHA-256) to form
/// the GCM associated data. Layout: `[tag][len][value]...` terminated by `0xff`,
/// per teslamotors/vehicle-command protocol.md.
class TeslaSignatureMetadata {
  static Uint8List serialize({
    required int signatureType,
    required int domain,
    required String vin,
    required Uint8List epoch,
    required int expiresAt,
    required int counter,
    int flags = 0,
  }) {
    final out = BytesBuilder();

    void tlv(int tag, List<int> value) {
      out.addByte(tag);
      out.addByte(value.length);
      out.add(value);
    }

    tlv(MetadataTag.signatureType, [signatureType]);
    tlv(MetadataTag.domain, [domain]);
    tlv(MetadataTag.personalization, ascii.encode(vin));
    tlv(MetadataTag.epoch, epoch);
    tlv(MetadataTag.expiresAt, _uint32be(expiresAt));
    tlv(MetadataTag.counter, _uint32be(counter));
    if (flags != 0) {
      tlv(MetadataTag.flags, _uint32be(flags));
    }
    out.addByte(MetadataTag.end);

    return out.toBytes();
  }
}

Uint8List _uint32be(int value) {
  final b = Uint8List(4);
  ByteData.view(b.buffer).setUint32(0, value, Endian.big);
  return b;
}
