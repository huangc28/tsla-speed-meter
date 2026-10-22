import CryptoKit
import Foundation

/// The TLV metadata Tesla authenticates alongside every signed message.
///
/// Adapted from teslamotors/vehicle-command (Apache-2.0)
/// internal/authentication/metadata.go: `[tag][len][value]...` in increasing
/// tag order, then `TAG_END` (0xff). The AES-GCM associated data is
/// `SHA256(serialized || message)`, where `message` is empty for AES-GCM.
public struct SignatureMetadata: Sendable, Equatable {
    public enum Error: Swift.Error, Equatable {
        /// Tags must be added in increasing order (programming error).
        case outOfOrder(Signatures_Tag)
        /// A value longer than 255 bytes cannot be length-prefixed.
        case fieldTooLong(Signatures_Tag)
    }

    private var bytes = Data()
    private var lastTag: Int?

    public init() {}

    /// Appends `(tag, value)`. An empty value is skipped, matching Go's
    /// `Add` returning early for a nil slice (absent proto3 bytes are nil).
    public mutating func add(_ tag: Signatures_Tag, _ value: Data) throws {
        if let lastTag, tag.rawValue < lastTag {
            throw Error.outOfOrder(tag)
        }
        guard !value.isEmpty else { return }
        guard value.count <= 255 else { throw Error.fieldTooLong(tag) }
        lastTag = tag.rawValue
        bytes.append(UInt8(tag.rawValue))
        bytes.append(UInt8(value.count))
        bytes.append(value)
    }

    public mutating func add(_ tag: Signatures_Tag, byte value: UInt8) throws {
        try add(tag, Data([value]))
    }

    public mutating func add(_ tag: Signatures_Tag, uint32BigEndian value: UInt32) throws {
        try add(tag, Data([
            UInt8(truncatingIfNeeded: value >> 24),
            UInt8(truncatingIfNeeded: value >> 16),
            UInt8(truncatingIfNeeded: value >> 8),
            UInt8(truncatingIfNeeded: value),
        ]))
    }

    /// The TLV string terminated with `TAG_END` (the `M` of protocol.md).
    public var serialized: Data {
        bytes + [UInt8(Signatures_Tag.end.rawValue)]
    }

    /// `SHA256(serialized || message)`: the AES-GCM associated data
    /// (metadata.go `Checksum`).
    public func checksum(message: Data = Data()) -> Data {
        Data(SHA256.hash(data: serialized + message))
    }
}

extension SignatureMetadata {
    /// Metadata of an AES-GCM-encrypted request
    /// (vehicle-command internal/authentication/peer.go `extractMetadata`).
    /// Flags are only included when non-zero, for backwards compatibility.
    public static func request(
        domain: UniversalMessage_Domain,
        vin: String,
        epoch: Data,
        expiresAt: UInt32,
        counter: UInt32,
        flags: UInt32
    ) throws -> SignatureMetadata {
        var meta = SignatureMetadata()
        try meta.add(.signatureType, byte: UInt8(Signatures_SignatureType.aesGcmPersonalized.rawValue))
        try meta.add(.domain, byte: UInt8(domain.rawValue))
        try meta.add(.personalization, Data(vin.utf8))
        try meta.add(.epoch, epoch)
        try meta.add(.expiresAt, uint32BigEndian: expiresAt)
        try meta.add(.counter, uint32BigEndian: counter)
        if flags > 0 {
            try meta.add(.flags, uint32BigEndian: flags)
        }
        return meta
    }

    /// Metadata the vehicle authenticates when it encrypts a response
    /// (vehicle-command internal/authentication/peer.go `responseMetadata`;
    /// cross-checked against Moblin Moblin/Integrations/Tesla/TeslaVehicle.swift
    /// `createResponseMetadata`). Unlike requests, flags are always included.
    public static func response(
        domain: UniversalMessage_Domain,
        vin: String,
        counter: UInt32,
        flags: UInt32,
        requestHash: Data,
        fault: UniversalMessage_MessageFault_E
    ) throws -> SignatureMetadata {
        var meta = SignatureMetadata()
        try meta.add(.signatureType, byte: UInt8(Signatures_SignatureType.aesGcmResponse.rawValue))
        try meta.add(.domain, byte: UInt8(domain.rawValue))
        try meta.add(.personalization, Data(vin.utf8))
        try meta.add(.counter, uint32BigEndian: counter)
        try meta.add(.flags, uint32BigEndian: flags)
        try meta.add(.requestHash, requestHash)
        try meta.add(.fault, uint32BigEndian: UInt32(fault.rawValue))
        return meta
    }

    /// Metadata of the session-info HMAC
    /// (vehicle-command internal/authentication/native.go `SessionInfoHMAC`).
    public static func sessionInfo(vin: String, challenge: Data) throws -> SignatureMetadata {
        var meta = SignatureMetadata()
        try meta.add(.signatureType, byte: UInt8(Signatures_SignatureType.hmac.rawValue))
        try meta.add(.personalization, Data(vin.utf8))
        try meta.add(.challenge, challenge)
        return meta
    }
}
