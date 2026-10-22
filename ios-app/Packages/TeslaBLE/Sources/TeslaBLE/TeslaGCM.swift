import CryptoKit
import Foundation

/// AES-128-GCM session crypto for Tesla BLE messages
/// (teslamotors/vehicle-command protocol.md "AES-GCM encryption").
/// The associated data is `SHA256(metadata)`, where `metadata` is the
/// serialized TLV including its `0xff` terminator (`SignatureMetadata.serialized`).
public struct TeslaGCM: Sendable {
    public struct Sealed: Sendable, Equatable {
        public let nonce: Data
        public let ciphertext: Data
        public let tag: Data
    }

    public let key: SymmetricKey

    public init(key: SymmetricKey) {
        self.key = key
    }

    /// Encrypts `plaintext`, authenticating `SHA256(metadata)`. A random
    /// 12-byte nonce is used unless one is given (fixed nonces are for tests).
    public func encrypt(plaintext: Data, metadata: Data, nonce: Data? = nil) throws -> Sealed {
        let gcmNonce = try nonce.map { try AES.GCM.Nonce(data: $0) } ?? AES.GCM.Nonce()
        let box = try AES.GCM.seal(
            plaintext,
            using: key,
            nonce: gcmNonce,
            authenticating: Self.associatedData(metadata)
        )
        return Sealed(nonce: Data(gcmNonce), ciphertext: box.ciphertext, tag: box.tag)
    }

    /// Decrypts and authenticates. Throws if the tag, nonce or metadata do
    /// not match.
    public func decrypt(nonce: Data, ciphertext: Data, tag: Data, metadata: Data) throws -> Data {
        let box = try AES.GCM.SealedBox(
            nonce: AES.GCM.Nonce(data: nonce),
            ciphertext: ciphertext,
            tag: tag
        )
        return try AES.GCM.open(box, using: key, authenticating: Self.associatedData(metadata))
    }

    static func associatedData(_ metadata: Data) -> Data {
        Data(SHA256.hash(data: metadata))
    }
}
