import Foundation
import Testing
@testable import TeslaBLE
import TeslaBLETestSupport

@Suite("Request builders")
struct TeslaRequestsTests {
    @Test("each GetVehicleData asks for exactly one category")
    func getVehicleData() throws {
        // CarServer.Action{vehicleAction(2){getVehicleData(1){one sub-message}}}:
        // getDriveState is field 4, getChargeState 2, getTirePressureState 14, getClosuresState 8.
        let expected: [VehicleDataCategory: (field: Int, hex: String)] = [
            .drive: (4, "12040a022200"),
            .charge: (2, "12040a021200"),
            .tirePressure: (14, "12040a027200"),
            .closures: (8, "12040a024200"),
        ]
        for category in VehicleDataCategory.allCases {
            let action = TeslaRequests.getVehicleDataAction(category)
            let request = action.vehicleAction.getVehicleData
            #expect(topLevelFieldNumbers(try request.serializedData()) == [expected[category]!.field])
            #expect(request.hasGetDriveState == (category == .drive))
            #expect(request.hasGetChargeState == (category == .charge))
            #expect(request.hasGetTirePressureState == (category == .tirePressure))
            #expect(request.hasGetClosuresState == (category == .closures))
            #expect(try action.serializedData().hex == expected[category]!.hex)
        }
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
