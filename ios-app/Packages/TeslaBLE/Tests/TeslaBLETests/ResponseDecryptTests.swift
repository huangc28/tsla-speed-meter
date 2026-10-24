import CryptoKit
import Foundation
import Testing
@testable import TeslaBLE
import TeslaBLETestSupport

extension UpstreamResponseVector {
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
        // The vector's request asks for drive, charge and tire pressure in
        // one GetVehicleData, as this package did before #39.
        #expect(plaintext.hex == "12080a06120022007200")
    }

    @Test("rejects the reply under a different request hash")
    func rejectsWrongRequestHash() throws {
        let session = try UpstreamResponseVector.session()
        let pending = try UpstreamResponseVector.pendingRequest()
        var other = SignedRequest(message: pending.message, requestHash: Data([0x04]) + pending.requestHash.dropFirst())
        let response = try UniversalMessage_RoutableMessage(serializedBytes: UpstreamResponseVector.response)
        #expect(throws: TeslaSessionError.invalidResponseTag(reportedFault: .rrorNone)) { try session.openResponse(response, to: &other) }
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

        let cases: [(UniversalMessage_RoutableMessage, UniversalMessage_MessageFault_E)] = [
            (flags, .rrorNone), (fault, .rrorBusy), (domain, .rrorNone), (counter, .rrorNone), (ciphertext, .rrorNone),
        ]
        for (altered, claimed) in cases {
            var request = try UpstreamResponseVector.pendingRequest()
            #expect(throws: TeslaSessionError.invalidResponseTag(reportedFault: claimed)) { try session.openResponse(altered, to: &request) }
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
        var request = try session.sign(payload: TeslaRequests.getVehicleDataAction(.drive).serializedData())
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
        #expect(throws: TeslaSessionError.invalidResponseTag(reportedFault: .rrorNone)) {
            try session.openResponse(VehicleSide.reply(to: request, plaintext: plaintext, counter: 3, vin: ProtocolDoc.vin, key: key), to: &otherRequest)
        }
    }

    @Test("authenticates the Go-sealed BUSY reply (flags 2) before raising its fault")
    func upstreamFaultVector() throws {
        let session = try UpstreamResponseVector.session()
        let reply = try UniversalMessage_RoutableMessage(serializedBytes: UpstreamResponseVector.faultResponse)
        #expect(reply.flags == 2)
        #expect(reply.signedMessageStatus.signedMessageFault == .rrorBusy)

        // The response metadata with flags 2 and fault 1 opens the upstream seal.
        let gcm = reply.signatureData.aesGcmResponseData
        let metadata = try SignatureMetadata.response(
            domain: .infotainment, vin: ProtocolDoc.vin, counter: gcm.counter, flags: 2,
            requestHash: UpstreamResponseVector.requestID, fault: .rrorBusy
        )
        #expect(try session.gcm.decrypt(
            nonce: gcm.nonce, ciphertext: reply.protobufMessageAsBytes, tag: gcm.tag, metadata: metadata.serialized
        ) == UpstreamResponseVector.faultResponsePlaintext)

        // openResponse authenticates (and consumes counter 2), then raises the fault.
        var request = try UpstreamResponseVector.pendingRequest()
        #expect(throws: TeslaSessionError.vehicleFault(.rrorBusy)) { try session.openResponse(reply, to: &request) }
        #expect(throws: TeslaSessionError.replayedResponse(counter: 2)) { try session.openResponse(reply, to: &request) }

        // A forged or stripped fault/flags never surfaces as a vehicle fault,
        // only as the unverified fault the reply claims.
        var forgedTag = reply
        forgedTag.signatureData.aesGcmResponseData.tag[0] ^= 0x01
        var clearedFault = reply
        clearedFault.signedMessageStatus.signedMessageFault = .rrorNone
        var otherFault = reply
        otherFault.signedMessageStatus.signedMessageFault = .rrorInvalidSignature
        var clearedFlags = reply
        clearedFlags.flags = 0
        let cases: [(UniversalMessage_RoutableMessage, UniversalMessage_MessageFault_E)] = [
            (forgedTag, .rrorBusy), (clearedFault, .rrorNone), (otherFault, .rrorInvalidSignature), (clearedFlags, .rrorBusy),
        ]
        for (altered, claimed) in cases {
            var fresh = try UpstreamResponseVector.pendingRequest()
            #expect(throws: TeslaSessionError.invalidResponseTag(reportedFault: claimed)) { try session.openResponse(altered, to: &fresh) }
        }
    }

    @Test("authenticates the Go-sealed MTU-exceeded reply with no payload field, then raises its fault")
    func upstreamEmptyFaultVector() throws {
        let session = try UpstreamResponseVector.session()
        let reply = try UniversalMessage_RoutableMessage(serializedBytes: UpstreamResponseVector.emptyFaultResponse)
        #expect(reply.payload == nil)
        #expect(reply.flags == 0)
        #expect(reply.signedMessageStatus.operationStatus == .rror)
        #expect(reply.signedMessageStatus.signedMessageFault == .rrorResponseMtuExceeded)
        #expect(reply.signatureData.aesGcmResponseData.counter == 3)

        var request = try UpstreamResponseVector.pendingRequest()
        #expect(throws: TeslaSessionError.vehicleFault(.rrorResponseMtuExceeded)) { try session.openResponse(reply, to: &request) }
        #expect(throws: TeslaSessionError.replayedResponse(counter: 3)) { try session.openResponse(reply, to: &request) }

        // With a broken tag, the claimed fault 25 comes back only as unverified.
        var forged = reply
        forged.signatureData.aesGcmResponseData.tag[0] ^= 0x01
        var fresh = try UpstreamResponseVector.pendingRequest()
        #expect(throws: TeslaSessionError.invalidResponseTag(reportedFault: .rrorResponseMtuExceeded)) {
            try session.openResponse(forged, to: &fresh)
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
