import Foundation
import Testing
@testable import TeslaBLE

@Suite("Request builders")
struct TeslaRequestsTests {
    @Test("GetVehicleData asks for drive, charge and tire-pressure state")
    func getVehicleData() throws {
        let action = TeslaRequests.getVehicleDataAction()
        let request = action.vehicleAction.getVehicleData
        #expect(request.hasGetDriveState)
        #expect(request.hasGetChargeState)
        #expect(request.hasGetTirePressureState)
        #expect(!request.hasGetClimateState)
        #expect(!request.hasGetLocationState)

        // CarServer.Action{vehicleAction(2){getVehicleData(1){getChargeState(2),
        // getDriveState(4), getTirePressureState(14)}}}; the same bytes the
        // upstream Go encoder produced for the response vector.
        #expect(try action.serializedData().hex == "12080a06120022007200")
    }

    @Test("session-info request carries the public key and uuid, no challenge field")
    func sessionInfoRequest() throws {
        let message = TeslaRequests.sessionInfoRequest(
            domain: .infotainment,
            clientPublicKey: ProtocolDoc.clientPublicKey,
            routingAddress: ProtocolDoc.sessionInfoRoutingAddress,
            uuid: ProtocolDoc.sessionInfoRequestUUID
        )
        // protocol.md "Request" example.
        #expect(message.toDestination.domain == .infotainment)
        #expect(message.fromDestination.routingAddress == ProtocolDoc.sessionInfoRoutingAddress)
        #expect(message.sessionInfoRequest.publicKey == ProtocolDoc.clientPublicKey)
        #expect(message.sessionInfoRequest.challenge.isEmpty)
        #expect(message.uuid == ProtocolDoc.sessionInfoRequestUUID)

        let random = TeslaRequests.sessionInfoRequest(domain: .vehicleSecurity, clientPublicKey: ProtocolDoc.clientPublicKey)
        #expect(random.fromDestination.routingAddress.count == 16)
        #expect(random.uuid.count == 16)
    }

    @Test("whitelist add is a PRESENT_KEY ToVCSECMessage with the key, role and form factor")
    func addKeyToWhitelist() throws {
        let envelope = try TeslaRequests.addKeyToWhitelist(publicKey: ProtocolDoc.clientPublicKey)
        let wire = try envelope.serializedData()

        let decoded = try VCSEC_ToVCSECMessage(serializedBytes: wire)
        #expect(decoded.signedMessage.signatureType == .presentKey)
        let unsigned = try VCSEC_UnsignedMessage(serializedBytes: decoded.signedMessage.protobufMessageAsBytes)
        let change = unsigned.whitelistOperation.addKeyToWhitelistAndAddPermissions
        #expect(change.key.publicKeyRaw == ProtocolDoc.clientPublicKey)
        #expect(change.keyRole == .driver)
        #expect(unsigned.whitelistOperation.metadataForKey.keyFormFactor == .iosDevice)
    }
}
