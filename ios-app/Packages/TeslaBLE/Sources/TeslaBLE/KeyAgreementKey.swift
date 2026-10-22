import CryptoKit
import Foundation

/// The client's long-lived P-256 key, seen only through the two operations the
/// protocol needs. A Secure Enclave key
/// (`SecureEnclave.P256.KeyAgreement.PrivateKey`) can implement this later
/// without the private scalar ever leaving the enclave.
public protocol KeyAgreementKey: Sendable {
    /// `ENCODE_PUBLIC(C)` in protocol.md: the 65-byte uncompressed point
    /// `0x04 || X || Y`.
    var publicKeyX963: Data { get }

    /// The raw ECDH shared secret with `remotePublicKeyX963`: the 32-byte
    /// big-endian X coordinate of the shared point.
    func sharedSecret(withPublicKeyX963 remotePublicKeyX963: Data) throws -> Data
}

/// A software P-256 key held in memory (CryptoKit).
public struct SoftwareKeyAgreementKey: KeyAgreementKey {
    public let privateKey: P256.KeyAgreement.PrivateKey

    public init(_ privateKey: P256.KeyAgreement.PrivateKey = .init()) {
        self.privateKey = privateKey
    }

    /// Loads a key from its 32-byte big-endian private scalar.
    public init(rawRepresentation: Data) throws {
        privateKey = try P256.KeyAgreement.PrivateKey(rawRepresentation: rawRepresentation)
    }

    public var publicKeyX963: Data {
        privateKey.publicKey.x963Representation
    }

    public func sharedSecret(withPublicKeyX963 remotePublicKeyX963: Data) throws -> Data {
        let remote = try P256.KeyAgreement.PublicKey(x963Representation: remotePublicKeyX963)
        let shared = try privateKey.sharedSecretFromKeyAgreement(with: remote)
        return shared.withUnsafeBytes { Data($0) }
    }
}

/// Session key derivation, teslamotors/vehicle-command pkg/protocol/protocol.md
/// ("Key Agreement") and internal/authentication/native.go `Exchange`:
/// `K = SHA1(BIG_ENDIAN(Sx, 32))[:16]` over NIST P-256.
public enum TeslaSessionKey {
    public static let byteCount = 16

    /// Derives the 16-byte AES-128-GCM key shared with one vehicle domain.
    public static func derive(
        clientKey: any KeyAgreementKey,
        vehiclePublicKeyX963: Data
    ) throws -> SymmetricKey {
        let sharedX = try clientKey.sharedSecret(withPublicKeyX963: vehiclePublicKeyX963)
        let digest = Insecure.SHA1.hash(data: sharedX)
        return SymmetricKey(data: Data(digest.prefix(byteCount)))
    }
}
