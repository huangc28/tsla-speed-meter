import CryptoKit
import Foundation
import Testing
@testable import TeslaBLE

/// A request/response pair produced by teslamotors/vehicle-command's own
/// Signer and Verifier (internal/authentication, commit fc5a191): the client
/// key is the protocol.md client key, the vehicle scalar is the one from
/// TestGCMKnown. The request asks for drive, charge and tire-pressure state
/// with FLAG_ENCRYPT_RESPONSE; the vehicle's reply was sealed by
/// `Verifier.Encrypt(response, RequestID(request), 1)` and checked with
/// `Signer.Decrypt` before being captured.
enum UpstreamResponseVector {
    static let vehiclePublicKey = Data(hex:
        "041431dc57c892b8dcc87ba59159031e12046b6febcdfb88f7b9c9e2a0fc2b7a1e323a4bd5a5696f103845bd1c4b9dd104d0fe87a3721314a03a7550406445705b")
    static let sessionInfo = Data(hex:
        "1241041431dc57c892b8dcc87ba59159031e12046b6febcdfb88f7b9c9e2a0fc2b7a1e323a4bd5a5696f103845bd1c4b9dd104d0fe87a3721314a03a7550406445705b"
        + "1a10ab99159b158cf4f871837318f7b6a50e")
    static let request = Data(hex:
        "320208033a121210a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a19a0310b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2a00302520a812c034b30eb1b7cf24b6a80010a"
        + "430a4104b2b6bc68c2da0665ce656815594996c62394edd8bea905fe781a754fe6a845a714330902f225e9269d466e05b349981fda9d85cc23c6fb444aa7"
        + "3b629105dc6e2a390a10ab99159b158cf4f871837318f7b6a50e120cd77889d0cd265946331ad9c91801253c0000002a106137b750c1a73bc6af5f73e0656facec")
    static let requestID = Data(hex: "056137b750c1a73bc6af5f73e0656facec")
    static let response = Data(hex:
        "32121210a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a13a020803920310b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2526e3103680c974b41b3a7cc19d81c13e10a90bc"
        + "02dbbe9f2045688de9322f0800b58010e4240134d70628124e48479208e6f6af91418625adab278dfff89a629ca70e5a2c7690978fc3f31988d6aa39fbdb92"
        + "15c58e95697cc3cea144c2e35a781a2e23f8f1c4bedff746324af898006a244a220a0c0a50d1e1d6c830f5b3fd958210011a10c62196262106f2768838a6bc"
        + "eb68e1b3")
    static let responsePlaintext = Data(hex:
        "126c1a250a021200e202060880f2d6ca06fd06008053438507004034438d0700006643900748d007002a210a022a0022060880f2d6ca06b0063cb806f4ff"
        + "ffffffffffffff01d506000072429a011f0a060880f2d6ca06320608a8edd6ca06159a9939401d000038402500004040")

    static func session() throws -> VehicleSession {
        try VehicleSession(
            vin: ProtocolDoc.vin,
            domain: .infotainment,
            sessionInfo: Signatures_SessionInfo(serializedBytes: sessionInfo),
            clientKey: ProtocolDoc.clientKey()
        )
    }

    /// The upstream request, wrapped with the request hash this package computes.
    static func pendingRequest() throws -> SignedRequest {
        let message = try UniversalMessage_RoutableMessage(serializedBytes: request)
        let tag = message.signatureData.aesGcmPersonalizedData.tag
        return SignedRequest(message: message, requestHash: Data([0x05]) + tag)
    }
}

@Suite("Response decrypt and verify")
struct ResponseDecryptTests {
    @Test("decrypts the reply sealed by vehicle-command's Verifier")
    func decryptsUpstreamVector() throws {
        let session = try UpstreamResponseVector.session()
        #expect(session.vehiclePublicKey == UpstreamResponseVector.vehiclePublicKey)

        var request = try UpstreamResponseVector.pendingRequest()
        #expect(request.requestHash == UpstreamResponseVector.requestID)
        #expect(request.message.flags == VehicleSession.defaultFlags)

        let response = try UniversalMessage_RoutableMessage(serializedBytes: UpstreamResponseVector.response)
        let payload = try session.openResponse(response, to: &request)
        #expect(payload.isEncrypted)
        #expect(payload.counter == 1)
        #expect(payload.plaintext == UpstreamResponseVector.responsePlaintext)

        let reading = try VehicleReading(responsePlaintext: payload.plaintext)
        #expect(reading.gear == .drive)
        #expect(reading.speedFloat == 60.5)
        #expect(reading.speed == 60)
        #expect(reading.drivePower == -12)
        #expect(reading.batteryLevel == 72)
        #expect(reading.batteryRangeMiles == 211.5)
        #expect(reading.chargingState == .disconnected)
        #expect(reading.chargerPower == 0)
        #expect(reading.tirePressureFrontLeft?.bar == 2.9)
        #expect(reading.tirePressureRearRight == nil)
        #expect(reading.tpmsLastSeenPressureTimeFrontLeft == Date(timeIntervalSince1970: 1_767_225_000))
        #expect(reading.driveStateTimestamp == Date(timeIntervalSince1970: 1_767_225_600))
    }

    @Test("our upstream request also decrypts on the vehicle side")
    func upstreamRequestDecrypts() throws {
        let session = try UpstreamResponseVector.session()
        let message = try UniversalMessage_RoutableMessage(serializedBytes: UpstreamResponseVector.request)
        let plaintext = try VehicleSide.openRequest(message, vin: ProtocolDoc.vin, key: session.gcm.key)
        #expect(plaintext == (try TeslaRequests.getVehicleDataAction().serializedData()))
    }

    @Test("rejects the reply under a different request hash")
    func rejectsWrongRequestHash() throws {
        let session = try UpstreamResponseVector.session()
        let pending = try UpstreamResponseVector.pendingRequest()
        var other = SignedRequest(message: pending.message, requestHash: Data([0x04]) + pending.requestHash.dropFirst())
        let response = try UniversalMessage_RoutableMessage(serializedBytes: UpstreamResponseVector.response)
        #expect(throws: TeslaSessionError.invalidResponseTag) { try session.openResponse(response, to: &other) }
    }

    @Test("rejects a reply whose authenticated fields were altered")
    func rejectsAlteredMetadata() throws {
        let session = try UpstreamResponseVector.session()
        let original = try UniversalMessage_RoutableMessage(serializedBytes: UpstreamResponseVector.response)

        var flags = original
        flags.flags = 1
        var fault = original
        fault.signedMessageStatus.signedMessageFault = .rrorBusy
        var domain = original
        domain.fromDestination.domain = .vehicleSecurity
        var counter = original
        counter.signatureData.aesGcmResponseData.counter = 2
        var ciphertext = original
        ciphertext.protobufMessageAsBytes[0] ^= 0x01

        for altered in [flags, fault, domain, counter, ciphertext] {
            var request = try UpstreamResponseVector.pendingRequest()
            #expect(throws: TeslaSessionError.invalidResponseTag) { try session.openResponse(altered, to: &request) }
        }
    }

    @Test("rejects a replayed reply for the same request")
    func rejectsReplay() throws {
        let session = try UpstreamResponseVector.session()
        var request = try UpstreamResponseVector.pendingRequest()
        let response = try UniversalMessage_RoutableMessage(serializedBytes: UpstreamResponseVector.response)
        _ = try session.openResponse(response, to: &request)
        #expect(throws: TeslaSessionError.replayedResponse(counter: 1)) { try session.openResponse(response, to: &request) }
    }

    @Test("round-trips a reply built the way the vehicle builds it")
    func roundTrip() throws {
        var session = try VehicleSession(
            sessionInfoResponse: ProtocolDoc.sessionInfoResponse(),
            requestUUID: ProtocolDoc.sessionInfoRequestUUID,
            vin: ProtocolDoc.vin,
            clientKey: ProtocolDoc.clientKey()
        )
        var request = try session.sign(payload: TeslaRequests.getVehicleDataAction().serializedData())
        let plaintext = Data(hex: UpstreamResponseVector.responsePlaintext.hex)

        // Out-of-order counters within the window are fine; repeats are not.
        let key = session.gcm.key
        let second = try VehicleSide.reply(to: request, plaintext: plaintext, counter: 2, vin: ProtocolDoc.vin, key: key, flags: 2)
        let first = try VehicleSide.reply(to: request, plaintext: plaintext, counter: 1, vin: ProtocolDoc.vin, key: key)
        #expect(try session.openResponse(second, to: &request).counter == 2)
        #expect(try session.openResponse(first, to: &request).plaintext == plaintext)
        #expect(throws: TeslaSessionError.replayedResponse(counter: 2)) { try session.openResponse(second, to: &request) }

        // A reply to a different request does not authenticate.
        var otherRequest = try session.sign(payload: Data([0x01]))
        #expect(throws: TeslaSessionError.invalidResponseTag) {
            try session.openResponse(VehicleSide.reply(to: request, plaintext: plaintext, counter: 3, vin: ProtocolDoc.vin, key: key), to: &otherRequest)
        }
    }

    @Test("surfaces an authenticated vehicle fault after decrypting")
    func encryptedFault() throws {
        var session = try UpstreamResponseVector.session()
        var request = try session.sign(payload: Data([0x01]))
        let reply = try VehicleSide.reply(
            to: request, plaintext: Data(), counter: 1, vin: ProtocolDoc.vin, key: session.gcm.key, fault: .rrorBusy
        )
        #expect(throws: TeslaSessionError.vehicleFault(.rrorBusy)) { try session.openResponse(reply, to: &request) }
    }

    @Test("passes a plaintext reply through, marked unencrypted; plaintext faults throw")
    func plaintextReplies() throws {
        var session = try UpstreamResponseVector.session()
        var request = try session.sign(payload: Data([0x01]))

        var plain = UniversalMessage_RoutableMessage()
        plain.fromDestination.domain = .infotainment
        plain.protobufMessageAsBytes = UpstreamResponseVector.responsePlaintext
        let payload = try session.openResponse(plain, to: &request)
        #expect(payload == ResponsePayload(plaintext: UpstreamResponseVector.responsePlaintext, isEncrypted: false, counter: nil))

        var fault = UniversalMessage_RoutableMessage()
        fault.signedMessageStatus.signedMessageFault = .rrorInvalidSignature
        #expect(throws: TeslaSessionError.vehicleFault(.rrorInvalidSignature)) { try session.openResponse(fault, to: &request) }

        var sessionInfoReply = UniversalMessage_RoutableMessage()
        sessionInfoReply.sessionInfo = Data([0x08, 0x01])
        #expect(throws: TeslaSessionError.unexpectedPayload) { try session.openResponse(sessionInfoReply, to: &request) }
    }
}
