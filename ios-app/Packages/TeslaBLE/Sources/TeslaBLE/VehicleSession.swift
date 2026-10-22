import CryptoKit
import Foundation

/// Errors from the session layer. No transport, so nothing here times out.
public enum TeslaSessionError: Error, Equatable {
    /// The reply does not carry the expected payload type.
    case unexpectedPayload
    /// The session info reply has no `session_info_tag`, so it is unauthenticated.
    case missingSessionInfoTag
    /// The reply's `request_uuid` is not the uuid of our request.
    case requestUUIDMismatch
    /// The session info HMAC tag did not verify.
    case invalidSessionInfoTag
    /// The response failed AES-GCM authentication.
    case invalidResponseTag
    /// The response counter was already used for this request (replay).
    case replayedResponse(counter: UInt32)
    /// The vehicle reported a protocol-layer fault.
    case vehicleFault(UniversalMessage_MessageFault_E)
    /// The anti-replay counter would roll over; a new handshake is needed.
    case counterRollover
}

/// A signed request ready to send, plus what is needed to authenticate the
/// vehicle's replies to it.
public struct SignedRequest: Sendable {
    /// The envelope to serialize and write to the vehicle.
    public let message: UniversalMessage_RoutableMessage

    /// The "request hash" of protocol.md "Request hash": the signature type
    /// byte followed by the request's AES-GCM tag
    /// (vehicle-command internal/authentication/peer.go `RequestID`).
    public let requestHash: Data

    /// Response counters already accepted for this request.
    public var responseCounters = SlidingWindow()

    public init(message: UniversalMessage_RoutableMessage, requestHash: Data) {
        self.message = message
        self.requestHash = requestHash
    }
}

/// An authenticated response payload.
public struct ResponsePayload: Sendable, Equatable {
    /// The plaintext `protobuf_message_as_bytes` (a `CarServer_Response` for
    /// the infotainment domain).
    public let plaintext: Data

    /// True when the vehicle encrypted the reply and it authenticated. False
    /// when the reply was plaintext: firmware older than 2024.38 ignores
    /// `FLAG_ENCRYPT_RESPONSE` (protocol.md "Response decryption").
    public let isEncrypted: Bool

    /// The response anti-replay counter, when encrypted.
    public let counter: UInt32?
}

/// Session state with one vehicle domain after an authenticated handshake:
/// the shared key, epoch, anti-replay counter and the vehicle clock.
///
/// Mirrors the Signer half of teslamotors/vehicle-command
/// internal/authentication/signer.go.
public struct VehicleSession: Sendable {
    /// The default request bit mask: `1 << FLAG_ENCRYPT_RESPONSE`, which asks
    /// the vehicle to encrypt its reply (vehicle-command pkg/vehicle/vehicle.go
    /// `DefaultFlags`).
    public static let defaultFlags = UInt32(1) << UInt32(UniversalMessage_Flags.flagEncryptResponse.rawValue)

    public let vin: String
    public let domain: UniversalMessage_Domain
    public let vehiclePublicKey: Data
    public let status: Signatures_Session_Info_Status
    public private(set) var epoch: Data
    public private(set) var counter: UInt32

    /// Vehicle domain clock (seconds into `epoch`) when session info was received.
    public let clockTime: UInt32
    /// Local monotonic instant matching `clockTime`.
    public let establishedAt: ContinuousClock.Instant

    let gcm: TeslaGCM
    private let clientPublicKey: Data

    /// Builds a session from an already-authenticated `SessionInfo`.
    public init(
        vin: String,
        domain: UniversalMessage_Domain,
        sessionInfo: Signatures_SessionInfo,
        clientKey: any KeyAgreementKey,
        establishedAt: ContinuousClock.Instant = .now
    ) throws {
        self.vin = vin
        self.domain = domain
        vehiclePublicKey = sessionInfo.publicKey
        status = sessionInfo.status
        epoch = sessionInfo.epoch
        counter = sessionInfo.counter
        clockTime = sessionInfo.clockTime
        self.establishedAt = establishedAt
        clientPublicKey = clientKey.publicKeyX963
        gcm = TeslaGCM(key: try TeslaSessionKey.derive(
            clientKey: clientKey,
            vehiclePublicKeyX963: sessionInfo.publicKey
        ))
    }

    /// Authenticates a session-info reply and builds the session from it.
    ///
    /// Follows protocol.md "Response authentication" and vehicle-command
    /// internal/dispatcher/dispatcher.go `checkForSessionUpdate` /
    /// internal/authentication/signer.go `NewAuthenticatedSigner`: the HMAC
    /// challenge is the reply's `request_uuid`, which must echo the uuid of
    /// the session-info request. Unauthenticated session info is rejected.
    /// Outside VCSEC an absent `request_uuid` is rejected too; VCSEC replies
    /// may omit it (protocol.md "Message encoding").
    public init(
        sessionInfoResponse response: UniversalMessage_RoutableMessage,
        requestUUID: Data,
        vin: String,
        clientKey: any KeyAgreementKey,
        establishedAt: ContinuousClock.Instant = .now
    ) throws {
        guard case .sessionInfo(let encodedInfo)? = response.payload else {
            throw TeslaSessionError.unexpectedPayload
        }
        guard case .sessionInfoTag(let tagData)? = response.signatureData.sigType,
              !tagData.tag.isEmpty
        else {
            throw TeslaSessionError.missingSessionInfoTag
        }
        // dispatcher.go `process` matches non-VCSEC replies on request_uuid;
        // VCSEC often leaves it empty (protocol.md), so only a non-empty
        // mismatch is rejected there.
        let isVCSEC = response.fromDestination.domain == .vehicleSecurity
        if response.requestUuid != requestUUID, !(isVCSEC && response.requestUuid.isEmpty) {
            throw TeslaSessionError.requestUUIDMismatch
        }
        let info = try Signatures_SessionInfo(serializedBytes: encodedInfo)
        try self.init(
            vin: vin,
            domain: response.fromDestination.domain,
            sessionInfo: info,
            clientKey: clientKey,
            establishedAt: establishedAt
        )
        let valid = try Self.isValidSessionInfoTag(
            tagData.tag,
            encodedInfo: encodedInfo,
            challenge: response.requestUuid,
            vin: vin,
            key: gcm.key
        )
        guard valid else { throw TeslaSessionError.invalidSessionInfoTag }
    }

    /// Checks `HMAC-SHA256(SESSION_INFO_KEY, M || encodedInfo)` in constant
    /// time, where `SESSION_INFO_KEY = HMAC-SHA256(K, "session info")`
    /// (vehicle-command internal/authentication/native.go `SessionInfoHMAC`).
    public static func isValidSessionInfoTag(
        _ tag: Data,
        encodedInfo: Data,
        challenge: Data,
        vin: String,
        key: SymmetricKey
    ) throws -> Bool {
        let metadata = try SignatureMetadata.sessionInfo(vin: vin, challenge: challenge)
        return HMAC<SHA256>.isValidAuthenticationCode(
            tag,
            authenticating: metadata.serialized + encodedInfo,
            using: sessionInfoKey(key)
        )
    }

    static func sessionInfoKey(_ key: SymmetricKey) -> SymmetricKey {
        SymmetricKey(data: Data(HMAC<SHA256>.authenticationCode(
            for: Data("session info".utf8),
            using: key
        )))
    }

    /// Vehicle-clock expiry for a request sent at `now`:
    /// `clockTime + elapsed + lifetime` (vehicle-command signer.go
    /// `encryptWithCounter`).
    public func expiresAt(now: ContinuousClock.Instant, lifetimeSeconds: UInt32) -> UInt32 {
        let elapsed = max(0, (now - establishedAt).components.seconds)
        return clockTime &+ UInt32(clamping: elapsed) &+ lifetimeSeconds
    }

    /// Encrypts `payload` (a serialized `CarServer_Action` for infotainment)
    /// into a signed RoutableMessage addressed to this domain
    /// (vehicle-command signer.go `Encrypt`; protocol.md "AES-GCM encryption").
    public mutating func sign(
        payload: Data,
        routingAddress: Data = .random(count: 16),
        uuid: Data = .random(count: 16),
        flags: UInt32 = VehicleSession.defaultFlags,
        lifetimeSeconds: UInt32 = 30,
        now: ContinuousClock.Instant = .now,
        nonce: Data? = nil
    ) throws -> SignedRequest {
        guard counter != UInt32.max else { throw TeslaSessionError.counterRollover }
        counter += 1
        let expiresAt = expiresAt(now: now, lifetimeSeconds: lifetimeSeconds)

        let metadata = try SignatureMetadata.request(
            domain: domain,
            vin: vin,
            epoch: epoch,
            expiresAt: expiresAt,
            counter: counter,
            flags: flags
        )
        let sealed = try gcm.encrypt(plaintext: payload, metadata: metadata.serialized, nonce: nonce)

        var message = UniversalMessage_RoutableMessage()
        message.toDestination.domain = domain
        message.fromDestination.routingAddress = routingAddress
        message.protobufMessageAsBytes = sealed.ciphertext
        message.uuid = uuid
        message.flags = flags
        message.signatureData.signerIdentity.publicKey = clientPublicKey
        message.signatureData.aesGcmPersonalizedData.epoch = epoch
        message.signatureData.aesGcmPersonalizedData.nonce = sealed.nonce
        message.signatureData.aesGcmPersonalizedData.counter = counter
        message.signatureData.aesGcmPersonalizedData.expiresAt = expiresAt
        message.signatureData.aesGcmPersonalizedData.tag = sealed.tag

        let requestHash = Data([UInt8(Signatures_SignatureType.aesGcmPersonalized.rawValue)]) + sealed.tag
        return SignedRequest(message: message, requestHash: requestHash)
    }

    /// Authenticates and decrypts a vehicle reply to `request`.
    ///
    /// Derived from vehicle-command internal/authentication/signer.go
    /// `Decrypt` + peer.go `responseMetadata` (how verifier.go `Encrypt`
    /// seals replies) and internal/dispatcher/session.go `decrypt`
    /// (anti-replay). Cross-checked with Moblin
    /// Moblin/Integrations/Tesla/TeslaVehicle.swift `executeCarServerAction`.
    ///
    /// - A reply without `AES_GCM_Response_data` is plaintext (firmware that
    ///   ignores `FLAG_ENCRYPT_RESPONSE`) and is returned with
    ///   `isEncrypted == false`, as vehicle-command's dispatcher does.
    /// - A `signedMessageStatus` fault is thrown after authentication, since
    ///   the fault is part of the authenticated metadata.
    public func openResponse(
        _ response: UniversalMessage_RoutableMessage,
        to request: inout SignedRequest
    ) throws -> ResponsePayload {
        let fault = response.signedMessageStatus.signedMessageFault
        guard case .aesGcmResponseData(let gcmData)? = response.signatureData.sigType else {
            if fault != .rrorNone { throw TeslaSessionError.vehicleFault(fault) }
            guard case .protobufMessageAsBytes(let plaintext)? = response.payload else {
                throw TeslaSessionError.unexpectedPayload
            }
            return ResponsePayload(plaintext: plaintext, isEncrypted: false, counter: nil)
        }

        let metadata = try SignatureMetadata.response(
            domain: response.fromDestination.domain,
            vin: vin,
            counter: gcmData.counter,
            flags: response.flags,
            requestHash: request.requestHash,
            fault: fault
        )
        let plaintext: Data
        do {
            plaintext = try gcm.decrypt(
                nonce: gcmData.nonce,
                ciphertext: response.protobufMessageAsBytes,
                tag: gcmData.tag,
                metadata: metadata.serialized
            )
        } catch {
            throw TeslaSessionError.invalidResponseTag
        }
        guard request.responseCounters.update(gcmData.counter) else {
            throw TeslaSessionError.replayedResponse(counter: gcmData.counter)
        }
        if fault != .rrorNone { throw TeslaSessionError.vehicleFault(fault) }
        return ResponsePayload(plaintext: plaintext, isEncrypted: true, counter: gcmData.counter)
    }
}

extension Data {
    /// `count` bytes from the system CSPRNG.
    public static func random(count: Int) -> Data {
        var generator = SystemRandomNumberGenerator()
        return Data((0..<count).map { _ in UInt8.random(in: .min ... .max, using: &generator) })
    }
}
