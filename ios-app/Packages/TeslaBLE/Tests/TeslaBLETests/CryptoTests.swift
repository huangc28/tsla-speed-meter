import CryptoKit
import Foundation
import Testing
@testable import TeslaBLE

// Ports of test/ble/ble_constants_test.dart, tesla_session_test.dart,
// tesla_key_store_test.dart, tesla_metadata_test.dart and tesla_gcm_test.dart
// (feature/goal-2-ble), plus the updated upstream protocol.md vector.

@Suite("TeslaBLEConstants.localName")
struct LocalNameTests {
    // S + hex(SHA1(vin)[:8]) + C, per vehicle-command VehicleLocalName.
    @Test("derives the advertised BLE name from the VIN")
    func derivesName() {
        #expect(TeslaBLEConstants.localName(forVIN: "5YJ30123456789ABC") == "Sade9a822faa374f8C")
    }

    @Test("is 18 chars: S + 16 hex + C")
    func shape() {
        let name = TeslaBLEConstants.localName(forVIN: "5YJSA1E14HF000000")
        #expect(name.count == 18)
        #expect(name.hasPrefix("S"))
        #expect(name.hasSuffix("C"))
        let middle = name.dropFirst().dropLast()
        #expect(middle.allSatisfy { "0123456789abcdef".contains($0) })
    }
}

@Suite("Key agreement and session key")
struct SessionKeyTests {
    // protocol.md "Key Agreement": K = SHA1(BIG_ENDIAN(Sx, 32))[:16].
    @Test("matches the protocol.md known-answer session key")
    func sessionKeyKnownAnswer() throws {
        let key = try TeslaSessionKey.derive(
            clientKey: ProtocolDoc.clientKey(),
            vehiclePublicKeyX963: ProtocolDoc.vehiclePublicKey
        )
        #expect(key.data.count == 16)
        #expect(key.data.hex == "1b2fce19967b79db696f909cff89ea9a")
    }

    // Dart TeslaKeyStore.publicKeyForPrivate vector: Q = d·G, uncompressed.
    @Test("derives the uncompressed public point from the private scalar")
    func publicKeyFromScalar() throws {
        let pub = try ProtocolDoc.clientKey().publicKeyX963
        #expect(pub.count == 65)
        #expect(pub.first == 0x04)
        #expect(pub == ProtocolDoc.clientPublicKey)
    }

    @Test("rejects a malformed vehicle public key")
    func rejectsBadPublicKey() throws {
        let bad = Data([0x04] + [UInt8](repeating: 0x01, count: 64))
        #expect(throws: (any Error).self) {
            try TeslaSessionKey.derive(clientKey: ProtocolDoc.clientKey(), vehiclePublicKeyX963: bad)
        }
    }
}

@Suite("SignatureMetadata")
struct SignatureMetadataTests {
    // Dart vector: protocol.md AES-GCM example as it stood without flags.
    @Test("serializes the request TLV exactly, terminated with 0xff (no flags)")
    func requestWithoutFlags() throws {
        let meta = try SignatureMetadata.request(
            domain: .infotainment,
            vin: ProtocolDoc.vin,
            epoch: ProtocolDoc.epoch,
            expiresAt: 2655,
            counter: 7,
            flags: 0
        )
        #expect(meta.serialized.hex ==
            "000105010103021135594a333031323334353637383941424303"
            + "104c463f9cc0d3d26906e982ed224adde6040400000a5f050400000007ff")
    }

    // Current protocol.md / vehicle-command protocol_doc_test.go vector:
    // FLAG_ENCRYPT_RESPONSE set, encoded under TAG_FLAGS = 7.
    @Test("includes TAG_FLAGS (0x07) when the request flags are non-zero")
    func requestWithFlags() throws {
        let meta = try SignatureMetadata.request(
            domain: .infotainment,
            vin: ProtocolDoc.vin,
            epoch: ProtocolDoc.epoch,
            expiresAt: 2655,
            counter: 7,
            flags: VehicleSession.defaultFlags
        )
        #expect(VehicleSession.defaultFlags == 2)
        #expect(meta.serialized.hex ==
            "000105010103021135594a333031323334353637383941424303104c463f9cc0d3d26906e982ed224adde6"
            + "040400000a5f050400000007070400000002ff")
    }

    // protocol.md "Response authentication" metadata example.
    @Test("serializes session-info HMAC metadata as in protocol.md")
    func sessionInfoMetadata() throws {
        let meta = try SignatureMetadata.sessionInfo(
            vin: ProtocolDoc.vin,
            challenge: ProtocolDoc.sessionInfoRequestUUID
        )
        #expect(meta.serialized.hex ==
            "000106021135594a333031323334353637383941424306101588d5a30eabc6f8fc9a951b11f6fd11ff")
    }

    // protocol.md "Response metadata" table; flags always present, fault as
    // a 32-bit big-endian integer.
    @Test("serializes response metadata with flags always present")
    func responseMetadata() throws {
        let meta = try SignatureMetadata.response(
            domain: .infotainment,
            vin: ProtocolDoc.vin,
            counter: 1,
            flags: 0,
            requestHash: Data([0x05, 0xAA, 0xBB]),
            fault: .rrorNone
        )
        #expect(meta.serialized.hex ==
            "000109" + "010103" + "021135594a3330313233343536373839414243"
            + "050400000001" + "070400000000" + "080305aabb" + "090400000000" + "ff")
    }

    @Test("rejects out-of-order tags and values over 255 bytes")
    func rejectsInvalidInput() throws {
        var meta = SignatureMetadata()
        try meta.add(.counter, uint32BigEndian: 1)
        #expect(throws: SignatureMetadata.Error.outOfOrder(.domain)) {
            try meta.add(.domain, byte: 3)
        }
        #expect(throws: SignatureMetadata.Error.fieldTooLong(.flags)) {
            try meta.add(.flags, Data(count: 256))
        }
    }

    @Test("checksum is SHA256 of the terminated TLV")
    func checksum() throws {
        var meta = SignatureMetadata()
        try meta.add(.domain, byte: 3)
        #expect(meta.checksum() == Data(SHA256.hash(data: Data([0x01, 0x01, 0x03, 0xFF]))))
    }
}

@Suite("TeslaGCM")
struct TeslaGCMTests {
    let gcm = TeslaGCM(key: SymmetricKey(data: ProtocolDoc.sessionKey))
    let nonce = Data(hex: "dbf79447fa156674dae1caed")
    let plaintext = Data(hex: "120452020801")
    let metadataNoFlags = Data(hex:
        "000105010103021135594a333031323334353637383941424303"
        + "104c463f9cc0d3d26906e982ed224adde6040400000a5f050400000007ff")
    let metadataWithFlags = Data(hex:
        "000105010103021135594a333031323334353637383941424303104c463f9cc0d3d26906e982ed224adde6"
        + "040400000a5f050400000007070400000002ff")

    // Dart vector (AAD = SHA256(metadata), cross-validated with Python).
    @Test("encrypt reproduces the Dart/protocol.md ciphertext and tag (no flags)")
    func encryptKnownAnswerNoFlags() throws {
        let sealed = try gcm.encrypt(plaintext: plaintext, metadata: metadataNoFlags, nonce: nonce)
        #expect(sealed.ciphertext.hex == "38038e8c0f2e")
        #expect(sealed.tag.hex == "8e128da165f162f4d7d2c8da866cf82a")
        #expect(sealed.nonce == nonce)
    }

    // vehicle-command internal/authentication/protocol_doc_test.go.
    @Test("encrypt reproduces the current protocol.md tag (FLAG_ENCRYPT_RESPONSE)")
    func encryptKnownAnswerWithFlags() throws {
        let sealed = try gcm.encrypt(plaintext: plaintext, metadata: metadataWithFlags, nonce: nonce)
        #expect(sealed.ciphertext.hex == "38038e8c0f2e")
        #expect(sealed.tag.hex == "c228e0ff64991481db3a7bbc133696c5")
    }

    @Test("decrypt round-trips the ciphertext back to plaintext")
    func roundTrip() throws {
        let sealed = try gcm.encrypt(plaintext: plaintext, metadata: metadataNoFlags)
        #expect(sealed.nonce.count == 12)
        let back = try gcm.decrypt(
            nonce: sealed.nonce, ciphertext: sealed.ciphertext, tag: sealed.tag, metadata: metadataNoFlags
        )
        #expect(back == plaintext)
    }

    @Test("decrypt rejects a tampered tag or different metadata")
    func rejectsTampering() throws {
        let sealed = try gcm.encrypt(plaintext: plaintext, metadata: metadataNoFlags, nonce: nonce)
        var badTag = sealed.tag
        badTag[badTag.startIndex] ^= 0xFF
        #expect(throws: (any Error).self) {
            try gcm.decrypt(nonce: nonce, ciphertext: sealed.ciphertext, tag: badTag, metadata: metadataNoFlags)
        }
        #expect(throws: (any Error).self) {
            try gcm.decrypt(nonce: nonce, ciphertext: sealed.ciphertext, tag: sealed.tag, metadata: metadataWithFlags)
        }
    }
}

@Suite("SlidingWindow")
struct SlidingWindowTests {
    // Port of vehicle-command internal/authentication/window_test.go.
    struct Case: Sendable {
        let counter: UInt32
        let window: UInt64
        let newCounter: UInt32
        let expectedCounter: UInt32
        let expectedWindow: UInt64
        let ok: Bool
    }

    static let cases: [Case] = [
        Case(counter: 100, window: 1 | (1 << 5), newCounter: 101, expectedCounter: 101, expectedWindow: 1 | (1 << 1) | (1 << 6), ok: true),
        Case(counter: 100, window: 1 | (1 << 5), newCounter: 103, expectedCounter: 103, expectedWindow: (1 << 2) | (1 << 3) | (1 << 8), ok: true),
        Case(counter: 100, window: 1 | (1 << 5), newCounter: 500, expectedCounter: 500, expectedWindow: 0, ok: true),
        Case(counter: 100, window: 1 | (1 << 5), newCounter: 98, expectedCounter: 100, expectedWindow: 1 | (1 << 1) | (1 << 5), ok: true),
        Case(counter: 100, window: 1 | (1 << 5), newCounter: 99, expectedCounter: 100, expectedWindow: 1 | (1 << 5), ok: false),
        Case(counter: 100, window: 1 | (1 << 5), newCounter: 3, expectedCounter: 100, expectedWindow: 1 | (1 << 5), ok: false),
        Case(counter: 100, window: 1 | (1 << 5), newCounter: 100, expectedCounter: 100, expectedWindow: 1 | (1 << 5), ok: false),
    ]

    @Test("matches the upstream sliding-window cases", arguments: cases)
    func upstreamCases(_ c: Case) {
        var window = SlidingWindow(counter: c.counter, history: c.window)
        let ok = window.update(c.newCounter)
        #expect(ok == c.ok)
        #expect(window.counter == c.expectedCounter)
        #expect(window.history == c.expectedWindow)
    }

    @Test("accepts the first counter, then rejects its replay")
    func firstUse() {
        var window = SlidingWindow()
        let first = window.update(1)
        let replay = window.update(1)
        let next = window.update(2)
        #expect(first)
        #expect(!replay)
        #expect(next)
    }
}
