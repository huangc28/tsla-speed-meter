import CryptoKit
import Foundation
import Testing
@testable import TeslaBLE
import TeslaBLETestSupport

@Suite("Session info authentication")
struct SessionInfoTests {
    // protocol.md "Response authentication": SESSION_INFO_KEY = HMAC(K, "session info").
    @Test("derives SESSION_INFO_KEY as in protocol.md")
    func sessionInfoKey() {
        let key = VehicleSession.sessionInfoKey(SymmetricKey(data: ProtocolDoc.sessionKey))
        #expect(key.data.hex == "fceb679ee7bca756fcd441bf238bf2f338629b41d9eb9c67be1b32c9672ce300")
    }

    @Test("accepts the protocol.md session info reply and adopts its state")
    func acceptsDocReply() throws {
        let session = try VehicleSession(
            sessionInfoResponse: ProtocolDoc.sessionInfoResponse(),
            requestUUID: ProtocolDoc.sessionInfoRequestUUID,
            vin: ProtocolDoc.vin,
            clientKey: ProtocolDoc.clientKey()
        )
        #expect(session.domain == .infotainment)
        #expect(session.counter == 6)
        #expect(session.clockTime == 2650)
        #expect(session.epoch == ProtocolDoc.epoch)
        #expect(session.vehiclePublicKey == ProtocolDoc.vehiclePublicKey)
        #expect(session.status == .ok)
        #expect(session.gcm.key.data == ProtocolDoc.sessionKey)
    }

    @Test("rejects a tampered tag, a tampered info, a missing tag and a foreign uuid")
    func rejectsBadReplies() throws {
        let key = try ProtocolDoc.clientKey()
        func open(_ response: UniversalMessage_RoutableMessage) throws {
            _ = try VehicleSession(
                sessionInfoResponse: response,
                requestUUID: ProtocolDoc.sessionInfoRequestUUID,
                vin: ProtocolDoc.vin,
                clientKey: key
            )
        }

        var badTag = ProtocolDoc.sessionInfoResponse()
        badTag.signatureData.sessionInfoTag.tag[0] ^= 0x01
        #expect(throws: TeslaSessionError.invalidSessionInfoTag) { try open(badTag) }

        var badInfo = ProtocolDoc.sessionInfoResponse()
        var info = try Signatures_SessionInfo(serializedBytes: ProtocolDoc.encodedSessionInfo)
        info.counter = 1
        badInfo.sessionInfo = try info.serializedData()
        #expect(throws: TeslaSessionError.invalidSessionInfoTag) { try open(badInfo) }

        var noTag = ProtocolDoc.sessionInfoResponse()
        noTag.signatureData = Signatures_SignatureData()
        #expect(throws: TeslaSessionError.missingSessionInfoTag) { try open(noTag) }

        var otherUUID = ProtocolDoc.sessionInfoResponse()
        otherUUID.requestUuid = Data(repeating: 0, count: 16)
        #expect(throws: TeslaSessionError.requestUUIDMismatch) { try open(otherUUID) }

        var noUUID = ProtocolDoc.sessionInfoResponse()
        noUUID.requestUuid = Data()
        #expect(throws: TeslaSessionError.requestUUIDMismatch) { try open(noUUID) }

        var wrongVIN = ProtocolDoc.sessionInfoResponse()
        wrongVIN.requestUuid = ProtocolDoc.sessionInfoRequestUUID
        #expect(throws: TeslaSessionError.invalidSessionInfoTag) {
            _ = try VehicleSession(
                sessionInfoResponse: wrongVIN,
                requestUUID: ProtocolDoc.sessionInfoRequestUUID,
                vin: "5YJ30123456789ABD",
                clientKey: key
            )
        }
    }
}

@Suite("Session info from VCSEC")
struct VCSECSessionInfoTests {
    /// A VCSEC session-info reply signed the way native.go `SessionInfoHMAC`
    /// does, with `challenge` as the HMAC challenge (empty = no TLV).
    func vcsecReply(requestUUID: Data) throws -> UniversalMessage_RoutableMessage {
        let metadata = try SignatureMetadata.sessionInfo(vin: ProtocolDoc.vin, challenge: requestUUID)
        let tag = HMAC<SHA256>.authenticationCode(
            for: metadata.serialized + ProtocolDoc.encodedSessionInfo,
            using: VehicleSession.sessionInfoKey(SymmetricKey(data: ProtocolDoc.sessionKey))
        )
        var reply = ProtocolDoc.sessionInfoResponse()
        reply.fromDestination.domain = .vehicleSecurity
        reply.requestUuid = requestUUID
        reply.signatureData.sessionInfoTag.tag = Data(tag)
        return reply
    }

    func open(_ reply: UniversalMessage_RoutableMessage) throws -> VehicleSession {
        try VehicleSession(
            sessionInfoResponse: reply,
            requestUUID: ProtocolDoc.sessionInfoRequestUUID,
            vin: ProtocolDoc.vin,
            clientKey: ProtocolDoc.clientKey()
        )
    }

    @Test("accepts a VCSEC reply that omits request_uuid")
    func acceptsMissingUUID() throws {
        let session = try open(vcsecReply(requestUUID: Data()))
        #expect(session.domain == .vehicleSecurity)
        #expect(session.counter == 6)
    }

    @Test("accepts a VCSEC reply that echoes our uuid, rejects a foreign one")
    func checksUUIDWhenPresent() throws {
        #expect(try open(vcsecReply(requestUUID: ProtocolDoc.sessionInfoRequestUUID)).domain == .vehicleSecurity)
        #expect(throws: TeslaSessionError.requestUUIDMismatch) {
            try open(vcsecReply(requestUUID: Data(repeating: 0x42, count: 16)))
        }
    }
}

@Suite("Signed requests")
struct SignedRequestTests {
    func docSession(at instant: ContinuousClock.Instant = .now) throws -> VehicleSession {
        try VehicleSession(
            sessionInfoResponse: ProtocolDoc.sessionInfoResponse(),
            requestUUID: ProtocolDoc.sessionInfoRequestUUID,
            vin: ProtocolDoc.vin,
            clientKey: ProtocolDoc.clientKey(),
            establishedAt: instant
        )
    }

    // protocol.md "AES-GCM encryption" worked example, end to end: counter
    // 6 -> 7, clock 2650 + 5 s -> expires 2655, flags 2.
    @Test("reproduces the protocol.md signed HVAC command byte for byte")
    func signsDocExample() throws {
        let t0 = ContinuousClock.now
        var session = try docSession(at: t0)
        let request = try session.sign(
            payload: Data(hex: "120452020801"),
            routingAddress: ProtocolDoc.sessionInfoRoutingAddress,
            uuid: Data(hex: "58406580528b6a5301391800b4fe9b99"),
            lifetimeSeconds: 5,
            now: t0,
            nonce: Data(hex: "dbf79447fa156674dae1caed")
        )

        var expected = UniversalMessage_RoutableMessage()
        expected.toDestination.domain = .infotainment
        expected.fromDestination.routingAddress = ProtocolDoc.sessionInfoRoutingAddress
        expected.protobufMessageAsBytes = Data(hex: "38038e8c0f2e")
        expected.signatureData.signerIdentity.publicKey = ProtocolDoc.clientPublicKey
        expected.signatureData.aesGcmPersonalizedData.epoch = ProtocolDoc.epoch
        expected.signatureData.aesGcmPersonalizedData.nonce = Data(hex: "dbf79447fa156674dae1caed")
        expected.signatureData.aesGcmPersonalizedData.counter = 7
        expected.signatureData.aesGcmPersonalizedData.expiresAt = 2655
        expected.signatureData.aesGcmPersonalizedData.tag = Data(hex: "c228e0ff64991481db3a7bbc133696c5")
        expected.flags = 2
        expected.uuid = Data(hex: "58406580528b6a5301391800b4fe9b99")

        #expect(request.message == expected)
        #expect(request.requestHash.hex == "05c228e0ff64991481db3a7bbc133696c5")
        #expect(session.counter == 7)
    }

    @Test("advances the counter and the expiry with elapsed local time")
    func countersAndExpiry() throws {
        let t0 = ContinuousClock.now
        var session = try docSession(at: t0)
        let first = try session.sign(payload: Data([0x01]), now: t0 + .seconds(10))
        let second = try session.sign(payload: Data([0x01]), now: t0 + .seconds(12.9))
        #expect(first.message.signatureData.aesGcmPersonalizedData.counter == 7)
        #expect(first.message.signatureData.aesGcmPersonalizedData.expiresAt == 2650 + 10 + 30)
        #expect(second.message.signatureData.aesGcmPersonalizedData.counter == 8)
        #expect(second.message.signatureData.aesGcmPersonalizedData.expiresAt == 2650 + 12 + 30)
        #expect(first.message.fromDestination.routingAddress.count == 16)
        #expect(first.message.uuid.count == 16)
        #expect(first.message.signatureData.aesGcmPersonalizedData.nonce != second.message.signatureData.aesGcmPersonalizedData.nonce)
    }

    @Test("the vehicle side can verify and decrypt a signed request")
    func vehicleDecryptsRequest() throws {
        var session = try docSession()
        let payload = try TeslaRequests.getVehicleDataAction(.drive).serializedData()
        let request = try session.sign(payload: payload)
        let wire = try request.message.serializedData()

        // What vehicle-command verifier.go `verifyGCM` does with the parsed request.
        let parsed = try UniversalMessage_RoutableMessage(serializedBytes: wire)
        #expect(try VehicleSide.openRequest(parsed, vin: ProtocolDoc.vin, key: SymmetricKey(data: ProtocolDoc.sessionKey)) == payload)
    }

    // vehicle-command internal/authentication/verifier_test.go TestGCMKnown:
    // a request encrypted to VCSEC, opened with the verifier's scalar (ECDH is
    // symmetric, so the same derivation applies from this side).
    @Test("decrypts the upstream TestGCMKnown request vector")
    func upstreamGCMKnown() throws {
        let encodedMessage = Data(hex:
            "320208023a0208005259296d587d130d34d74d6d5c628c73c1f8ef99cc4ae1c95b97671474980ccc79"
            + "46a90a2f7971a5c837b96c9cc1e8075d1aab92bc8557b7fdf2dcf9ddbb90e236246db699788e585e8b"
            + "0ea84752e0090cc80c4384d27ca6fcdd216a470a061204bb0ca3712a3d0a10eaabe301b4b4a1243118"
            + "a40825220115120c45d29af664e2ff8fd49218b718ffffffff0f2550c300002a106d846705ba5c143f"
            + "94257275a2ca701f")
        let signerPublicKey = Data(hex:
            "0450444fabe062f6ffc59de654373e1aa84aa4f053f365f3746fbaaa8ad5d5875e8279ba379b4788e9"
            + "148f5000bd1fe085d18925e8d047239cfa0d9cd23417b714")
        let verifierScalar = Data(hex: "9d9c5e86d5a83057965ca94b5faeff116c275d08ca91e839bd2dea59c2229b81")
        let expectedPlaintext = Data(hex:
            "82014a2a480a430a41044b96809e66821b4553ff2b427a52d50843a2f718fd56f2ad93d46a8b1db74d"
            + "d6190f20b6b82e85a8eac40e867b9a0cf74f364f03e9946e25ceee9934b19cb603120102ca01090a07"
            + "7465737476696e")

        let key = try TeslaSessionKey.derive(
            clientKey: SoftwareKeyAgreementKey(rawRepresentation: verifierScalar),
            vehiclePublicKeyX963: signerPublicKey
        )
        let message = try UniversalMessage_RoutableMessage(serializedBytes: encodedMessage)
        #expect(message.toDestination.domain == .vehicleSecurity)
        #expect(message.signatureData.aesGcmPersonalizedData.epoch.hex == "eaabe301b4b4a1243118a40825220115")
        #expect(try VehicleSide.openRequest(message, vin: "testvin", key: key) == expectedPlaintext)
    }

    @Test("refuses to roll the counter over")
    func counterRollover() throws {
        var info = Signatures_SessionInfo()
        info.counter = .max
        info.publicKey = ProtocolDoc.vehiclePublicKey
        info.epoch = ProtocolDoc.epoch
        var session = try VehicleSession(
            vin: ProtocolDoc.vin, domain: .infotainment, sessionInfo: info, clientKey: ProtocolDoc.clientKey()
        )
        #expect(throws: TeslaSessionError.counterRollover) { try session.sign(payload: Data([1])) }
    }
}

/// The vehicle's half of the protocol, test-only, written from
/// vehicle-command internal/authentication/verifier.go (`verifyGCM`,
/// `Encrypt`) and peer.go (`extractMetadata`, `responseMetadata`).
enum VehicleSide {
    static func openRequest(_ message: UniversalMessage_RoutableMessage, vin: String, key: SymmetricKey) throws -> Data {
        let data = message.signatureData.aesGcmPersonalizedData
        let metadata = try SignatureMetadata.request(
            domain: message.toDestination.domain,
            vin: vin,
            epoch: data.epoch,
            expiresAt: data.expiresAt,
            counter: data.counter,
            flags: message.flags
        )
        return try TeslaGCM(key: key).decrypt(
            nonce: data.nonce, ciphertext: message.protobufMessageAsBytes, tag: data.tag, metadata: metadata.serialized
        )
    }

    /// Builds the vehicle's encrypted reply to `request`, as verifier.go `Encrypt` does.
    static func reply(
        to request: SignedRequest,
        plaintext: Data,
        counter: UInt32,
        vin: String,
        key: SymmetricKey,
        flags: UInt32 = 0,
        fault: UniversalMessage_MessageFault_E = .rrorNone
    ) throws -> UniversalMessage_RoutableMessage {
        var response = UniversalMessage_RoutableMessage()
        response.toDestination.routingAddress = request.message.fromDestination.routingAddress
        response.fromDestination.domain = request.message.toDestination.domain
        response.requestUuid = request.message.uuid
        response.flags = flags
        if fault != .rrorNone {
            response.signedMessageStatus.signedMessageFault = fault
        }
        let metadata = try SignatureMetadata.response(
            domain: response.fromDestination.domain,
            vin: vin,
            counter: counter,
            flags: flags,
            requestHash: request.requestHash,
            fault: fault
        )
        let sealed = try TeslaGCM(key: key).encrypt(plaintext: plaintext, metadata: metadata.serialized)
        response.protobufMessageAsBytes = sealed.ciphertext
        response.signatureData.aesGcmResponseData.counter = counter
        response.signatureData.aesGcmResponseData.nonce = sealed.nonce
        response.signatureData.aesGcmResponseData.tag = sealed.tag
        return response
    }
}
